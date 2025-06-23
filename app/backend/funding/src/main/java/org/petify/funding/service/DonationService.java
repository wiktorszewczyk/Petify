package org.petify.funding.service;

import org.petify.funding.client.AchievementClient;
import org.petify.funding.client.ShelterClient;
import org.petify.funding.dto.DonationIntentRequest;
import org.petify.funding.dto.DonationRequest;
import org.petify.funding.dto.DonationResponse;
import org.petify.funding.dto.DonationStatistics;
import org.petify.funding.exception.ResourceNotFoundException;
import org.petify.funding.model.Donation;
import org.petify.funding.model.DonationStatus;
import org.petify.funding.model.DonationType;
import org.petify.funding.model.Fundraiser;
import org.petify.funding.model.Payment;
import org.petify.funding.model.PaymentStatus;
import org.petify.funding.repository.DonationRepository;
import org.petify.funding.repository.FundraiserRepository;
import org.petify.funding.repository.PaymentRepository;

import feign.FeignException;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;

@RequiredArgsConstructor
@Service
@Slf4j
@Getter
@Setter
public class DonationService {

    private final DonationRepository donationRepository;
    private final PaymentRepository paymentRepository;
    private final FundraiserRepository fundraiserRepository;
    private final ShelterClient shelterClient;
    private final AchievementClient achievementClient;

    @Transactional
    public DonationResponse createDraft(DonationIntentRequest request, Jwt jwt) {
        log.info("Creating draft donation for shelter {} by user {}", request.getShelterId(), jwt.getSubject());

        DonationRequest donationRequest = convertToDonationRequest(request);
        enrichDonorInformation(donationRequest, jwt);
        validateDonationRequest(donationRequest);
        validateShelterExists(donationRequest.getShelterId());

        if (donationRequest.getPetId() != null) {
            validatePetExists(donationRequest.getShelterId(), donationRequest.getPetId());
        }

        if (donationRequest.getFundraiserId() != null) {
            validateFundraiserExists(donationRequest.getFundraiserId(), donationRequest.getShelterId());
        }

        Donation donation = donationRequest.toEntity();
        donation.setStatus(DonationStatus.PENDING);
        Donation saved = donationRepository.save(donation);

        trackDonationAchievement(saved);

        log.info("Draft donation created successfully with ID: {}", saved.getId());
        return DonationResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public Page<DonationResponse> getAll(Pageable pageable, DonationType type) {
        Page<Donation> page = (type == null)
                ? donationRepository.findAll(pageable)
                : donationRepository.findAllByDonationType(type, pageable);
        return page.map(DonationResponse::fromEntity);
    }

    @Transactional(readOnly = true)
    public DonationResponse get(Long id) {
        Donation donation = donationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Donation not found: " + id));
        return DonationResponse.fromEntity(donation);
    }

    @Transactional(readOnly = true)
    public Page<DonationResponse> getForShelter(Long shelterId, Pageable pageable) {
        return donationRepository.findByShelterId(shelterId, pageable)
                .map(DonationResponse::fromEntity);
    }

    @Transactional(readOnly = true)
    public Page<DonationResponse> getForPet(Long petId, Pageable pageable) {
        return donationRepository.findByPetId(petId, pageable)
                .map(DonationResponse::fromEntity);
    }

    @Transactional(readOnly = true)
    public Page<DonationResponse> getForFundraiser(Long fundraiserId, Pageable pageable) {
        return donationRepository.findByFundraiserId(fundraiserId, pageable)
                .map(DonationResponse::fromEntity);
    }

    @Transactional(readOnly = true)
    public Page<DonationResponse> getUserDonations(Pageable pageable) {
        String username = getCurrentUsername();
        if (username == null) {
            throw new RuntimeException("User not authenticated");
        }
        return donationRepository.findByDonorUsernameOrderByCreatedAtDesc(username, pageable)
                .map(DonationResponse::fromEntity);
    }

    @Transactional
    public void delete(Long id) {
        try {
            Donation donation = donationRepository.findById(id)
                    .orElseThrow(() -> new ResourceNotFoundException("Donation not found: " + id));

            if (donation.hasPendingPayments()) {
                throw new RuntimeException("Cannot delete donation with pending payments");
            }

            donationRepository.deleteById(id);
            log.info("Donation {} deleted successfully", id);

        } catch (EmptyResultDataAccessException ex) {
            throw new ResourceNotFoundException("Donation with id: " + id + " not found");
        }
    }

    @Transactional
    public DonationResponse cancelDonation(Long donationId) {
        String currentUsername = getCurrentUsername();

        Donation donation = donationRepository.findById(donationId)
                .orElseThrow(() -> new ResourceNotFoundException("Donation not found: " + donationId));

        if (!donation.getDonorUsername().equals(currentUsername)) {
            throw new RuntimeException("Can only cancel your own donations");
        }

        if (!donation.canBeCancelled()) {
            throw new RuntimeException("Donation cannot be cancelled in current state: " + donation.getStatus());
        }

        List<Payment> activePayments = donation.getPayments().stream()
                .filter(p -> p.getStatus() == PaymentStatus.PENDING || p.getStatus() == PaymentStatus.PROCESSING)
                .toList();

        for (Payment payment : activePayments) {
            try {
                payment.setStatus(PaymentStatus.CANCELLED);
                paymentRepository.save(payment);
                log.info("Cancelled payment {} for donation {}", payment.getId(), donationId);
            } catch (Exception e) {
                log.warn("Failed to cancel payment {} for donation {}: {}",
                        payment.getId(), donationId, e.getMessage());
            }
        }

        donation.setStatus(DonationStatus.CANCELLED);
        Donation saved = donationRepository.save(donation);

        log.info("Donation {} cancelled by user {}", donationId, currentUsername);
        return DonationResponse.fromEntity(saved);
    }

    @Transactional
    public DonationResponse refundDonation(Long donationId, BigDecimal amount) {
        Donation donation = donationRepository.findById(donationId)
                .orElseThrow(() -> new ResourceNotFoundException("Donation not found: " + donationId));

        if (!donation.canBeRefunded()) {
            throw new RuntimeException("Donation cannot be refunded in current state: " + donation.getStatus());
        }

        List<Payment> successfulPayments = donation.getPayments().stream()
                .filter(p -> p.getStatus() == PaymentStatus.SUCCEEDED)
                .toList();

        if (successfulPayments.isEmpty()) {
            throw new RuntimeException("No successful payments found for refund");
        }

        BigDecimal totalRefundAmount = BigDecimal.ZERO;
        BigDecimal refundAmountLeft = amount != null ? amount : donation.getTotalPaidAmount();

        for (Payment payment : successfulPayments) {
            if (refundAmountLeft.compareTo(BigDecimal.ZERO) <= 0) {
                break;
            }

            BigDecimal paymentRefundAmount = refundAmountLeft.min(payment.getAmount());

            try {
                PaymentStatus newStatus = paymentRefundAmount.compareTo(payment.getAmount()) == 0
                        ? PaymentStatus.REFUNDED
                        : PaymentStatus.PARTIALLY_REFUNDED;

                payment.setStatus(newStatus);
                paymentRepository.save(payment);

                totalRefundAmount = totalRefundAmount.add(paymentRefundAmount);
                refundAmountLeft = refundAmountLeft.subtract(paymentRefundAmount);

                log.info("Refunded {} from payment {} for donation {}",
                        paymentRefundAmount, payment.getId(), donationId);
            } catch (Exception e) {
                log.error("Failed to refund payment {} for donation {}: {}",
                        payment.getId(), donationId, e.getMessage());
            }
        }

        if (totalRefundAmount.compareTo(donation.getTotalPaidAmount()) >= 0) {
            donation.setStatus(DonationStatus.REFUNDED);
        }

        Donation saved = donationRepository.save(donation);
        log.info("Donation {} refunded (total amount: {})", donationId, totalRefundAmount);

        return DonationResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public DonationStatistics getShelterDonationStats(Long shelterId) {
        Instant lastDonationInstant = donationRepository.getLastDonationDateByShelterId(shelterId);
        LocalDate lastDonationDate = null;

        if (lastDonationInstant != null) {
            lastDonationDate = lastDonationInstant.atZone(ZoneId.systemDefault()).toLocalDate();
        }

        return DonationStatistics.builder()
                .shelterId(shelterId)
                .totalDonations(donationRepository.countByShelterId(shelterId))
                .totalAmount(donationRepository.sumAmountByShelterId(shelterId))
                .completedDonations(donationRepository.countCompletedByShelterId(shelterId))
                .pendingDonations(donationRepository.countPendingByShelterId(shelterId))
                .averageDonationAmount(donationRepository.averageAmountByShelterId(shelterId))
                .lastDonationDate(lastDonationDate)
                .build();
    }

    private void enrichDonorInformation(DonationRequest request, Jwt jwt) {
        if (jwt != null) {
            if (request.getDonorUsername() == null && !Boolean.TRUE.equals(request.getAnonymous())) {
                request.setDonorUsername(jwt.getSubject());
            } else if (Boolean.TRUE.equals(request.getAnonymous())) {
                request.setDonorUsername(null);
            }
        }
    }

    private void validateDonationRequest(DonationRequest request) {
        if (!Boolean.TRUE.equals(request.getAnonymous())
                && (request.getDonorUsername() == null || request.getDonorUsername().trim().isEmpty())) {
            throw new RuntimeException("Donor username is required for non-anonymous donations");
        }

        if (request.getDonationType() == DonationType.MONEY) {
            if (request.getAmount() == null || request.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
                throw new RuntimeException("Amount must be positive for monetary donations");
            }
            if (request.getItemName() != null || request.getUnitPrice() != null || request.getQuantity() != null) {
                throw new RuntimeException("Material donation fields should not be set for monetary donations");
            }
        }

        if (request.getDonationType() == DonationType.MATERIAL) {
            if (request.getItemName() == null || request.getItemName().trim().isEmpty()) {
                throw new RuntimeException("Item name is required for material donations");
            }
            if (request.getUnitPrice() == null || request.getUnitPrice().compareTo(BigDecimal.ZERO) <= 0) {
                throw new RuntimeException("Unit price must be positive for material donations");
            }
            if (request.getQuantity() == null || request.getQuantity() <= 0) {
                throw new RuntimeException("Quantity must be positive for material donations");
            }
        }
    }

    private void validateShelterExists(Long shelterId) {
        try {
            log.debug("Validating shelter ID: {}", shelterId);
            shelterClient.validateShelter(shelterId);
            log.debug("Shelter {} is valid and active", shelterId);
        } catch (FeignException.NotFound ex) {
            log.warn("Shelter {} not found", shelterId);
            throw new ResourceNotFoundException("Shelter not found: " + shelterId);
        } catch (FeignException.Forbidden ex) {
            log.warn("Shelter {} is not active", shelterId);
            throw new RuntimeException("Shelter is not active and cannot accept donations: " + shelterId);
        } catch (Exception ex) {
            log.error("Error validating shelter {}: {}", shelterId, ex.getMessage(), ex);
            throw new RuntimeException("Could not verify shelter existence: " + ex.getMessage());
        }
    }

    private void validatePetExists(Long shelterId, Long petId) {
        try {
            log.debug("Validating pet {} in shelter {}", petId, shelterId);
            shelterClient.validatePetInShelter(shelterId, petId);
            log.debug("Pet {} in shelter {} is valid for donations", petId, shelterId);
        } catch (FeignException.NotFound ex) {
            log.warn("Pet {} not found in shelter {} or doesn't belong to this shelter", petId, shelterId);
            throw new ResourceNotFoundException("Pet not found in shelter: pet=" + petId + ", shelter=" + shelterId);
        } catch (FeignException.Forbidden ex) {
            log.warn("Shelter {} is not active", shelterId);
            throw new RuntimeException("Shelter is not active: " + shelterId);
        } catch (FeignException.Gone ex) {
            log.warn("Pet {} is archived", petId);
            throw new RuntimeException("Pet is archived and not available for donations: " + petId);
        } catch (Exception ex) {
            log.error("Error validating pet {} in shelter {}: {}", petId, shelterId, ex.getMessage(), ex);
            throw new RuntimeException("Could not verify pet existence: " + ex.getMessage());
        }
    }

    private void validateFundraiserExists(Long fundraiserId, Long shelterId) {
        log.debug("Validating fundraiser {} for shelter {}", fundraiserId, shelterId);
        Fundraiser fundraiser = fundraiserRepository.findById(fundraiserId)
                .orElseThrow(() -> new ResourceNotFoundException("Fundraiser not found: " + fundraiserId));

        if (!fundraiser.getShelterId().equals(shelterId)) {
            throw new RuntimeException("Fundraiser does not belong to the specified shelter");
        }

        if (!fundraiser.canAcceptDonations()) {
            throw new RuntimeException("Fundraiser is not accepting donations in current state: " + fundraiser.getStatus());
        }

        log.debug("Fundraiser {} is valid for donations", fundraiserId);
    }

    private String getCurrentUsername() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof Jwt jwt) {
            return jwt.getSubject();
        }
        return authentication != null ? authentication.getName() : null;
    }

    private DonationRequest convertToDonationRequest(DonationIntentRequest request) {
        DonationRequest donationRequest = new DonationRequest();
        donationRequest.setShelterId(request.getShelterId());
        donationRequest.setPetId(request.getPetId());
        donationRequest.setFundraiserId(request.getFundraiserId());
        donationRequest.setDonationType(request.getDonationType());
        donationRequest.setMessage(request.getMessage());
        donationRequest.setAnonymous(request.getAnonymous());

        if (request.getDonationType() == DonationType.MONEY) {
            donationRequest.setAmount(request.getAmount());
        }

        if (request.getDonationType() == DonationType.MATERIAL) {
            donationRequest.setItemName(request.getItemName());
            donationRequest.setUnitPrice(request.getUnitPrice());
            donationRequest.setQuantity(request.getQuantity());
        }

        return donationRequest;
    }

    private void trackDonationAchievement(Donation donation) {
        try {
            String donorUsername = donation.getDonorUsername();
            if (donorUsername != null && !donorUsername.trim().isEmpty()) {
                achievementClient.trackSupportProgress();
                log.info("Tracked support achievement for donation {} by user: {}",
                        donation.getId(), donorUsername);
            }
        } catch (Exception e) {
            log.error("Failed to track achievement for donation {} by user: {}",
                    donation.getId(), donation.getDonorUsername(), e);
        }
    }
}
