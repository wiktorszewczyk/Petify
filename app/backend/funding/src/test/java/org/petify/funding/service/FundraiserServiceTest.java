package org.petify.funding.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.funding.dto.FundraiserRequest;
import org.petify.funding.model.Currency;
import org.petify.funding.repository.DonationRepository;
import org.petify.funding.repository.FundraiserRepository;
import org.springframework.security.oauth2.jwt.Jwt;

import java.math.BigDecimal;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FundraiserServiceTest {

    @Mock
    private FundraiserRepository fundraiserRepository;
    @Mock
    private DonationRepository donationRepository;
    @InjectMocks
    private FundraiserService fundraiserService;

    @Mock
    private Jwt jwt;

    @Test
    void createMainFundraiserWhenOneExistsThrows() {
        FundraiserRequest request = new FundraiserRequest();
        request.setShelterId(1L);
        request.setTitle("test");
        request.setGoalAmount(BigDecimal.TEN);
        request.setCurrency(Currency.PLN);
        request.setIsMain(true);

        when(fundraiserRepository.existsByShelterIdAndIsMainTrue(anyLong())).thenReturn(true);

        assertThatThrownBy(() -> fundraiserService.create(request, jwt))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Shelter already has a main fundraiser");
    }

    @Test
    void updateFundraiserSettingMainWhenExistsThrows() {
        var existing = org.petify.funding.model.Fundraiser.builder()
                .id(1L)
                .shelterId(1L)
                .isMain(false)
                .goalAmount(BigDecimal.TEN)
                .currency(Currency.PLN)
                .title("old")
                .build();

        FundraiserRequest request = new FundraiserRequest();
        request.setShelterId(1L);
        request.setTitle("new");
        request.setGoalAmount(BigDecimal.TEN);
        request.setCurrency(Currency.PLN);
        request.setIsMain(true);

        when(fundraiserRepository.findById(1L)).thenReturn(java.util.Optional.of(existing));
        when(fundraiserRepository.existsByShelterIdAndIsMainTrue(1L)).thenReturn(true);

        assertThatThrownBy(() -> fundraiserService.update(1L, request, jwt))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Shelter already has a main fundraiser");
    }

    @Test
    void updateStatusChangesStatus() {
        var fundraiser = org.petify.funding.model.Fundraiser.builder()
                .id(2L)
                .shelterId(1L)
                .status(org.petify.funding.model.FundraiserStatus.ACTIVE)
                .goalAmount(BigDecimal.TEN)
                .currency(Currency.PLN)
                .title("test")
                .build();

        when(fundraiserRepository.findById(2L)).thenReturn(java.util.Optional.of(fundraiser));
        when(fundraiserRepository.save(org.mockito.Mockito.any())).thenAnswer(inv -> inv.getArgument(0));
        when(donationRepository.sumCompletedDonationsByFundraiserId(2L)).thenReturn(BigDecimal.ZERO);
        when(donationRepository.countCompletedDonationsByFundraiserId(2L)).thenReturn(0L);

        var response = fundraiserService.updateStatus(2L, org.petify.funding.model.FundraiserStatus.CANCELLED);

        org.assertj.core.api.Assertions.assertThat(response.getStatus())
                .isEqualTo(org.petify.funding.model.FundraiserStatus.CANCELLED);
    }

    @Test
    void getStatsCalculatesProgress() {
        var fundraiser = org.petify.funding.model.Fundraiser.builder()
                .id(3L)
                .shelterId(1L)
                .goalAmount(new BigDecimal("100"))
                .currency(Currency.PLN)
                .title("fund")
                .build();

        when(fundraiserRepository.findById(3L)).thenReturn(java.util.Optional.of(fundraiser));
        when(donationRepository.sumCompletedDonationsByFundraiserId(3L)).thenReturn(new BigDecimal("40"));
        when(donationRepository.countCompletedDonationsByFundraiserId(3L)).thenReturn(2L);
        when(donationRepository.countUniqueDonorsByFundraiserId(3L)).thenReturn(2L);
        when(donationRepository.sumCompletedDonationsByFundraiserIdAndDateAfter(org.mockito.Mockito.eq(3L), org.mockito.Mockito.any())).thenReturn(new BigDecimal("10"));

        var stats = fundraiserService.getStats(3L);

        org.assertj.core.api.Assertions.assertThat(stats.getProgressPercentage()).isEqualTo(40.0);
        org.assertj.core.api.Assertions.assertThat(stats.getRemainingAmount()).isEqualByComparingTo("60");
    }

    @Test
    void deleteFundraiserWithDonationsThrows() {
        var fundraiser = org.petify.funding.model.Fundraiser.builder()
                .id(4L)
                .shelterId(1L)
                .goalAmount(BigDecimal.TEN)
                .currency(Currency.PLN)
                .title("t")
                .build();

        when(fundraiserRepository.findById(4L)).thenReturn(java.util.Optional.of(fundraiser));
        when(donationRepository.countByFundraiserId(4L)).thenReturn(1L);

        assertThatThrownBy(() -> fundraiserService.delete(4L))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Cannot delete fundraiser with existing donations");
    }

    @Test
    void getFundraiserNotFoundThrows() {
        when(fundraiserRepository.findById(99L)).thenReturn(java.util.Optional.empty());

        assertThatThrownBy(() -> fundraiserService.get(99L))
                .isInstanceOf(org.petify.funding.exception.ResourceNotFoundException.class);
    }
}