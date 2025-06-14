package org.petify.funding.service;

import org.petify.funding.dto.FundraiserRequest;
import org.petify.funding.dto.FundraiserResponse;
import org.petify.funding.dto.FundraiserStats;
import org.petify.funding.exception.ResourceNotFoundException;
import org.petify.funding.model.Fundraiser;
import org.petify.funding.model.FundraiserStatus;
import org.petify.funding.repository.DonationRepository;
import org.petify.funding.repository.FundraiserRepository;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class FundraiserService {

    private final FundraiserRepository fundraiserRepository;
    private final DonationRepository donationRepository;

    @Transactional
    public FundraiserResponse create(FundraiserRequest request, Jwt jwt) {
        log.info("Creating fundraiser for shelter: {}", request.getShelterId());

        if (request.getIsMain() && fundraiserRepository.existsByShelterIdAndIsMainTrue(request.getShelterId())) {
            throw new IllegalStateException("Shelter already has a main fundraiser");
        }

        String username = jwt.getSubject();

        Fundraiser fundraiser = Fundraiser.builder()
                .shelterId(request.getShelterId())
                .title(request.getTitle())
                .description(request.getDescription())
                .goalAmount(request.getGoalAmount())
                .currency(request.getCurrency())
                .type(request.getType())
                .endDate(request.getEndDate())
                .isMain(request.getIsMain())
                .needs(request.getNeeds())
                .createdBy(username)
                .build();

        fundraiser = fundraiserRepository.save(fundraiser);
        return mapToResponse(fundraiser);
    }

    public FundraiserResponse get(Long id) {
        Fundraiser fundraiser = fundraiserRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fundraiser not found with id: " + id));
        return mapToResponse(fundraiser);
    }

    public Page<FundraiserResponse> getByShelter(Long shelterId, Pageable pageable) {
        return fundraiserRepository.findByShelterId(shelterId, pageable)
                .map(this::mapToResponse);
    }

    public Page<FundraiserResponse> getActiveFundraisers(Pageable pageable) {
        return fundraiserRepository.findActiveByStatus(FundraiserStatus.ACTIVE, pageable)
                .map(this::mapToResponse);
    }

    public Optional<FundraiserResponse> getMainFundraiser(Long shelterId) {
        return fundraiserRepository.findByShelterIdAndIsMainTrue(shelterId)
                .map(this::mapToResponse);
    }

    @Transactional
    public FundraiserResponse update(Long id, FundraiserRequest request, Jwt jwt) {
        Fundraiser fundraiser = fundraiserRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fundraiser not found with id: " + id));

        if (request.getIsMain() && !fundraiser.getIsMain()
                && fundraiserRepository.existsByShelterIdAndIsMainTrue(request.getShelterId())) {
            throw new IllegalStateException("Shelter already has a main fundraiser");
        }

        fundraiser.setTitle(request.getTitle());
        fundraiser.setDescription(request.getDescription());
        fundraiser.setGoalAmount(request.getGoalAmount());
        fundraiser.setCurrency(request.getCurrency());
        fundraiser.setType(request.getType());
        fundraiser.setEndDate(request.getEndDate());
        fundraiser.setIsMain(request.getIsMain());
        fundraiser.setNeeds(request.getNeeds());

        fundraiser = fundraiserRepository.save(fundraiser);
        return mapToResponse(fundraiser);
    }

    @Transactional
    public FundraiserResponse updateStatus(Long id, FundraiserStatus status) {
        Fundraiser fundraiser = fundraiserRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fundraiser not found with id: " + id));

        fundraiser.setStatus(status);
        fundraiser = fundraiserRepository.save(fundraiser);
        return mapToResponse(fundraiser);
    }

    public FundraiserStats getStats(Long id) {
        Fundraiser fundraiser = fundraiserRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fundraiser not found with id: " + id));

        BigDecimal currentAmount = donationRepository.sumCompletedDonationsByFundraiserId(id);
        if (currentAmount == null) {
            currentAmount = BigDecimal.ZERO;
        }

        Long totalDonations = donationRepository.countCompletedDonationsByFundraiserId(id);
        Long uniqueDonors = donationRepository.countUniqueDonorsByFundraiserId(id);

        Instant oneWeekAgo = Instant.now().minus(7, ChronoUnit.DAYS);
        BigDecimal lastWeekAmount = donationRepository.sumCompletedDonationsByFundraiserIdAndDateAfter(id, oneWeekAgo);
        if (lastWeekAmount == null) {
            lastWeekAmount = BigDecimal.ZERO;
        }

        BigDecimal averageDonation = totalDonations > 0
                ? currentAmount.divide(BigDecimal.valueOf(totalDonations), 2, RoundingMode.HALF_UP) :
                BigDecimal.ZERO;

        double progressPercentage = fundraiser.calculateProgress(currentAmount);
        BigDecimal remainingAmount = fundraiser.getGoalAmount().subtract(currentAmount);

        return FundraiserStats.builder()
                .fundraiserId(id)
                .title(fundraiser.getTitle())
                .goalAmount(fundraiser.getGoalAmount())
                .currentAmount(currentAmount)
                .remainingAmount(remainingAmount.max(BigDecimal.ZERO))
                .progressPercentage(progressPercentage)
                .totalDonations(totalDonations)
                .uniqueDonors(uniqueDonors)
                .averageDonation(averageDonation)
                .lastWeekAmount(lastWeekAmount)
                .isGoalReached(currentAmount.compareTo(fundraiser.getGoalAmount()) >= 0)
                .build();
    }

    @Transactional
    public void delete(Long id) {
        Fundraiser fundraiser = fundraiserRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fundraiser not found with id: " + id));

        Long donationCount = donationRepository.countByFundraiserId(id);
        if (donationCount > 0) {
            throw new IllegalStateException("Cannot delete fundraiser with existing donations");
        }

        fundraiserRepository.delete(fundraiser);
    }

    private FundraiserResponse mapToResponse(Fundraiser fundraiser) {
        BigDecimal currentAmount = donationRepository.sumCompletedDonationsByFundraiserId(fundraiser.getId());
        if (currentAmount == null) {
            currentAmount = BigDecimal.ZERO;
        }

        Long donationCount = donationRepository.countCompletedDonationsByFundraiserId(fundraiser.getId());
        double progressPercentage = fundraiser.calculateProgress(currentAmount);

        return FundraiserResponse.builder()
                .id(fundraiser.getId())
                .shelterId(fundraiser.getShelterId())
                .title(fundraiser.getTitle())
                .description(fundraiser.getDescription())
                .goalAmount(fundraiser.getGoalAmount())
                .currency(fundraiser.getCurrency())
                .status(fundraiser.getStatus())
                .type(fundraiser.getType())
                .startDate(fundraiser.getStartDate())
                .endDate(fundraiser.getEndDate())
                .isMain(fundraiser.getIsMain())
                .needs(fundraiser.getNeeds())
                .createdBy(fundraiser.getCreatedBy())
                .createdAt(fundraiser.getCreatedAt())
                .updatedAt(fundraiser.getUpdatedAt())
                .completedAt(fundraiser.getCompletedAt())
                .cancelledAt(fundraiser.getCancelledAt())
                .currentAmount(currentAmount)
                .donationCount(donationCount)
                .progressPercentage(progressPercentage)
                .canAcceptDonations(fundraiser.canAcceptDonations())
                .build();
    }
}
