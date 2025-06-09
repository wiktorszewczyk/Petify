package org.petify.funding.service;

import org.petify.funding.client.ShelterClient;
import org.petify.funding.dto.DonationIntentRequest;
import org.petify.funding.dto.DonationRequest;
import org.petify.funding.dto.DonationResponse;
import org.petify.funding.dto.DonationStatistics;
import org.petify.funding.exception.ResourceNotFoundException;
import org.petify.funding.model.Donation;
import org.petify.funding.model.DonationStatus;
import org.petify.funding.model.DonationType;
import org.petify.funding.model.Payment;
import org.petify.funding.model.PaymentStatus;
import org.petify.funding.repository.DonationRepository;
import org.petify.funding.repository.PaymentRepository;

import feign.FeignException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@RequiredArgsConstructor
@Service
@Slf4j
public class DonationService {

    private final DonationRepository donationRepository;
    private final PaymentRepository paymentRepository;
    private final ShelterClient shelterClient;

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

        Donation donation = donationRequest.toEntity();
        donation.setStatus(DonationStatus.PENDING);
        Donation saved = donationRepository.save(donation);

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
        return DonationStatistics.builder()
                .shelterId(shelterId)
                .totalDonations(donationRepository.countByShelterId(shelterId))
                .totalAmount(donationRepository.sumAmountByShelterId(shelterId))
                .completedDonations(donationRepository.countCompletedByShelterId(shelterId))
                .pendingDonations(donationRepository.countPendingByShelterId(shelterId))
                .averageDonationAmount(donationRepository.averageAmountByShelterId(shelterId))
                .build();
    }

    private void enrichDonorInformation(DonationRequest request, Jwt jwt) {
        if (jwt != null) {
            if (request.getDonorUsername() == null) {
                request.setDonorUsername(jwt.getSubject());
            }
            if (request.getDonorId() == null && jwt.getClaim("userId") != null) {
                request.setDonorId(jwt.getClaim("userId"));
            }
        }
    }

    private void validateDonationRequest(DonationRequest request) {
        if (request.getDonorUsername() == null || request.getDonorUsername().trim().isEmpty()) {
            throw new RuntimeException("Donor username is required");
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
            if (request.getAmount() != null) {
                throw new RuntimeException("Amount should not be set manually for material donations - it will be calculated automatically");
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
        donationRequest.setDonationType(request.getDonationType());
        donationRequest.setAmount(request.getAmount());
        donationRequest.setMessage(request.getMessage());
        donationRequest.setAnonymous(request.getAnonymous());
        donationRequest.setItemName(request.getItemName());
        donationRequest.setUnitPrice(request.getUnitPrice());
        donationRequest.setQuantity(request.getQuantity());
        return donationRequest;
    }
}
