package org.petify.funding.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.funding.client.AchievementClient;
import org.petify.funding.model.Currency;
import org.petify.funding.model.DonationStatus;
import org.petify.funding.model.MonetaryDonation;
import org.petify.funding.repository.DonationRepository;
import org.petify.funding.repository.PaymentRepository;

import java.math.BigDecimal;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DonationStatusUpdateServiceTest {

    @Mock
    private DonationRepository donationRepository;
    @Mock
    private PaymentRepository paymentRepository;
    @Mock
    private AchievementClient achievementClient;

    @InjectMocks
    private DonationStatusUpdateService service;

    @Test
    void updateDonationStatusSetsDonatedAt() {
        MonetaryDonation donation = MonetaryDonation.builder()
                .id(1L)
                .shelterId(1L)
                .amount(BigDecimal.TEN)
                .currency(Currency.PLN)
                .status(DonationStatus.PENDING)
                .build();

        when(donationRepository.findById(anyLong())).thenReturn(Optional.of(donation));
        when(donationRepository.save(donation)).thenReturn(donation);

        service.updateDonationStatus(1L, DonationStatus.COMPLETED);

        assertThat(donation.getStatus()).isEqualTo(DonationStatus.COMPLETED);
        assertThat(donation.getDonatedAt()).isNotNull();
    }
}