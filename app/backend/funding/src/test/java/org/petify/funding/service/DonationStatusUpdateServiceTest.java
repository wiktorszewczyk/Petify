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

    @Test
    void updateDonationStatusSetsCancelledAt() {
        MonetaryDonation donation = MonetaryDonation.builder()
                .id(2L)
                .shelterId(1L)
                .amount(BigDecimal.TEN)
                .currency(Currency.PLN)
                .status(DonationStatus.PENDING)
                .build();

        when(donationRepository.findById(2L)).thenReturn(Optional.of(donation));
        when(donationRepository.save(donation)).thenReturn(donation);

        service.updateDonationStatus(2L, DonationStatus.CANCELLED);

        assertThat(donation.getStatus()).isEqualTo(DonationStatus.CANCELLED);
    }

    @Test
    void handleSucceededPaymentUpdatesDonationAndAddsXp() {
        MonetaryDonation donation = MonetaryDonation.builder()
                .id(3L)
                .shelterId(1L)
                .amount(BigDecimal.valueOf(20))
                .currency(Currency.PLN)
                .donorUsername("john")
                .status(DonationStatus.PENDING)
                .build();
        var payment = org.petify.funding.model.Payment.builder()
                .id(4L)
                .donation(donation)
                .status(org.petify.funding.model.PaymentStatus.PENDING)
                .amount(BigDecimal.valueOf(20))
                .build();

        when(paymentRepository.findById(4L)).thenReturn(Optional.of(payment));
        when(donationRepository.findById(3L)).thenReturn(Optional.of(donation));
        when(donationRepository.save(donation)).thenReturn(donation);

        service.handlePaymentStatusChange(4L, org.petify.funding.model.PaymentStatus.SUCCEEDED);

        assertThat(donation.getStatus()).isEqualTo(DonationStatus.COMPLETED);
        assertThat(donation.getDonatedAt()).isNotNull();
        org.mockito.Mockito.verify(achievementClient)
                .addDonationExperiencePointsForUser("john", 20);
    }

    @Test
    void handleSucceededPaymentWhenAlreadyCompletedDoesNothing() {
        MonetaryDonation donation = MonetaryDonation.builder()
                .id(5L)
                .shelterId(1L)
                .amount(BigDecimal.valueOf(15))
                .currency(Currency.PLN)
                .donorUsername("john")
                .status(DonationStatus.COMPLETED)
                .build();
        var payment = org.petify.funding.model.Payment.builder()
                .id(6L)
                .donation(donation)
                .status(org.petify.funding.model.PaymentStatus.PENDING)
                .amount(BigDecimal.valueOf(15))
                .build();

        when(paymentRepository.findById(6L)).thenReturn(Optional.of(payment));

        service.handlePaymentStatusChange(6L, org.petify.funding.model.PaymentStatus.SUCCEEDED);

        assertThat(donation.getStatus()).isEqualTo(DonationStatus.COMPLETED);
        org.mockito.Mockito.verifyNoInteractions(donationRepository);
    }

    @Test
    void handleFailedPaymentWithMaxAttemptsMarksDonationFailed() {
        MonetaryDonation donation = MonetaryDonation.builder()
                .id(7L)
                .shelterId(1L)
                .amount(BigDecimal.TEN)
                .currency(Currency.PLN)
                .paymentAttempts(3)
                .status(DonationStatus.PENDING)
                .build();
        var payment = org.petify.funding.model.Payment.builder()
                .id(8L)
                .donation(donation)
                .status(org.petify.funding.model.PaymentStatus.FAILED)
                .amount(BigDecimal.TEN)
                .build();

        when(paymentRepository.findById(8L)).thenReturn(Optional.of(payment));
        when(donationRepository.findById(7L)).thenReturn(Optional.of(donation));
        when(donationRepository.save(donation)).thenReturn(donation);

        service.handlePaymentStatusChange(8L, org.petify.funding.model.PaymentStatus.FAILED);

        assertThat(donation.getStatus()).isEqualTo(DonationStatus.FAILED);
    }

    @Test
    void handleFailedPaymentWithoutMaxAttemptsDoesNothing() {
        MonetaryDonation donation = MonetaryDonation.builder()
                .id(9L)
                .shelterId(1L)
                .amount(BigDecimal.TEN)
                .currency(Currency.PLN)
                .paymentAttempts(1)
                .status(DonationStatus.PENDING)
                .build();
        var payment = org.petify.funding.model.Payment.builder()
                .id(10L)
                .donation(donation)
                .status(org.petify.funding.model.PaymentStatus.FAILED)
                .amount(BigDecimal.TEN)
                .build();

        when(paymentRepository.findById(10L)).thenReturn(Optional.of(payment));
        when(donationRepository.findById(9L)).thenReturn(Optional.of(donation));

        service.handlePaymentStatusChange(10L, org.petify.funding.model.PaymentStatus.FAILED);

        assertThat(donation.getStatus()).isEqualTo(DonationStatus.PENDING);
        org.mockito.Mockito.verifyNoMoreInteractions(donationRepository);
    }
}