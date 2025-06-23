package org.petify.funding.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.funding.client.AchievementClient;
import org.petify.funding.client.ShelterClient;
import org.petify.funding.dto.DonationIntentRequest;
import org.petify.funding.model.DonationType;
import org.petify.funding.repository.DonationRepository;
import org.petify.funding.repository.FundraiserRepository;
import org.petify.funding.repository.PaymentRepository;

import java.math.BigDecimal;
import org.springframework.security.oauth2.jwt.Jwt;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DonationServiceTest {

    @Mock
    private DonationRepository donationRepository;
    @Mock
    private PaymentRepository paymentRepository;
    @Mock
    private FundraiserRepository fundraiserRepository;
    @Mock
    private ShelterClient shelterClient;
    @Mock
    private AchievementClient achievementClient;
    @InjectMocks
    private DonationService donationService;

    @Test
    void createDraftWithoutUsernameShouldFail() {
        DonationIntentRequest request = new DonationIntentRequest();
        request.setShelterId(1L);
        request.setDonationType(DonationType.MONEY);
        request.setAmount(BigDecimal.TEN);
        request.setAnonymous(false);

        Jwt jwt = org.mockito.Mockito.mock(Jwt.class);
        when(jwt.getSubject()).thenReturn(null);

        assertThatThrownBy(() -> donationService.createDraft(request, jwt))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Donor username is required");
    }

    @Test
    void createDraftAnonymousUserUsernameShouldBeNull() {
        DonationIntentRequest request = new DonationIntentRequest();
        request.setShelterId(1L);
        request.setDonationType(DonationType.MONEY);
        request.setAmount(BigDecimal.TEN);
        request.setAnonymous(true);

        Jwt jwt = org.mockito.Mockito.mock(Jwt.class);
        when(jwt.getSubject()).thenReturn("john");

        doNothing().when(shelterClient).validateShelter(anyLong());
        when(donationRepository.save(org.mockito.Mockito.any()))
                .thenAnswer(inv -> {
                    var donation = (org.petify.funding.model.Donation) inv.getArgument(0);
                    donation.setId(10L);
                    return donation;
                });

        var response = donationService.createDraft(request, jwt);

        org.assertj.core.api.Assertions.assertThat(response.getDonorUsername()).isNull();
        org.assertj.core.api.Assertions.assertThat(response.getId()).isEqualTo(10L);
    }

    @Test
    void createDraftWithZeroAmountThrows() {
        DonationIntentRequest request = new DonationIntentRequest();
        request.setShelterId(1L);
        request.setDonationType(DonationType.MONEY);
        request.setAmount(BigDecimal.ZERO);

        Jwt jwt = org.mockito.Mockito.mock(Jwt.class);
        when(jwt.getSubject()).thenReturn("john");

        assertThatThrownBy(() -> donationService.createDraft(request, jwt))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Amount must be positive");
    }

    @Test
    void createDraftIgnoresMaterialFieldsForMoneyDonation() {
        DonationIntentRequest request = new DonationIntentRequest();
        request.setShelterId(1L);
        request.setDonationType(DonationType.MONEY);
        request.setAmount(BigDecimal.TEN);
        request.setItemName("Toy");
        request.setUnitPrice(BigDecimal.ONE);
        request.setQuantity(2);

        Jwt jwt = org.mockito.Mockito.mock(Jwt.class);
        when(jwt.getSubject()).thenReturn("john");

        doNothing().when(shelterClient).validateShelter(anyLong());
        when(donationRepository.save(org.mockito.Mockito.any()))
                .thenAnswer(inv -> {
                    var donation = (org.petify.funding.model.Donation) inv.getArgument(0);
                    donation.setId(11L);
                    donation.setDonationType(DonationType.MONEY);
                    return donation;
                });

        var response = donationService.createDraft(request, jwt);

        org.assertj.core.api.Assertions.assertThat(response.getDonationType())
                .isEqualTo(DonationType.MONEY);
        org.assertj.core.api.Assertions.assertThat(response.getItemName()).isNull();
        org.assertj.core.api.Assertions.assertThat(response.getId()).isEqualTo(11L);
    }

    @Test
    void createDraftMaterialDonationMissingItemNameThrows() {
        DonationIntentRequest request = new DonationIntentRequest();
        request.setShelterId(1L);
        request.setDonationType(DonationType.MATERIAL);
        request.setUnitPrice(BigDecimal.TEN);
        request.setQuantity(1);

        Jwt jwt = org.mockito.Mockito.mock(Jwt.class);
        when(jwt.getSubject()).thenReturn("john");

        assertThatThrownBy(() -> donationService.createDraft(request, jwt))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Item name is required");
    }

    @Test
    void cancelDonationNotOwnerThrows() {
        var donation = org.petify.funding.model.MonetaryDonation.builder()
                .id(1L)
                .shelterId(1L)
                .amount(BigDecimal.TEN)
                .donorUsername("owner")
                .build();
        when(donationRepository.findById(1L)).thenReturn(java.util.Optional.of(donation));

        var jwt = org.mockito.Mockito.mock(Jwt.class);
        when(jwt.getSubject()).thenReturn("other");
        org.springframework.security.core.context.SecurityContextHolder.getContext()
                .setAuthentication(new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(jwt, null));

        assertThatThrownBy(() -> donationService.cancelDonation(1L))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Can only cancel your own donations");
    }

    @Test
    void cancelDonationCancelsPaymentsAndDonation() {
        var payment = org.petify.funding.model.Payment.builder()
                .id(2L)
                .status(org.petify.funding.model.PaymentStatus.PENDING)
                .build();
        var donation = org.petify.funding.model.MonetaryDonation.builder()
                .id(1L)
                .shelterId(1L)
                .status(org.petify.funding.model.DonationStatus.PENDING)
                .amount(BigDecimal.TEN)
                .donorUsername("owner")
                .payments(java.util.List.of(payment))
                .build();

        when(donationRepository.findById(1L)).thenReturn(java.util.Optional.of(donation));
        when(donationRepository.save(org.mockito.Mockito.any())).thenAnswer(inv -> inv.getArgument(0));
        when(paymentRepository.save(org.mockito.Mockito.any())).thenAnswer(inv -> inv.getArgument(0));

        var jwt = org.mockito.Mockito.mock(Jwt.class);
        when(jwt.getSubject()).thenReturn("owner");
        org.springframework.security.core.context.SecurityContextHolder.getContext()
                .setAuthentication(new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(jwt, null));

        var result = donationService.cancelDonation(1L);

        org.assertj.core.api.Assertions.assertThat(result.getStatus())
                .isEqualTo(org.petify.funding.model.DonationStatus.CANCELLED);
        org.assertj.core.api.Assertions.assertThat(payment.getStatus())
                .isEqualTo(org.petify.funding.model.PaymentStatus.CANCELLED);
    }

    @Test
    void refundDonationWithoutSuccessfulPaymentsThrows() {
        var payment = org.petify.funding.model.Payment.builder()
                .id(2L)
                .status(org.petify.funding.model.PaymentStatus.FAILED)
                .amount(BigDecimal.TEN)
                .build();
        var donation = org.petify.funding.model.MonetaryDonation.builder()
                .id(1L)
                .shelterId(1L)
                .amount(BigDecimal.TEN)
                .status(org.petify.funding.model.DonationStatus.COMPLETED)
                .donorUsername("owner")
                .payments(java.util.List.of(payment))
                .build();

        when(donationRepository.findById(1L)).thenReturn(java.util.Optional.of(donation));

        assertThatThrownBy(() -> donationService.refundDonation(1L, null))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Donation cannot be refunded");
    }

    @Test
    void refundDonationPartialAmountUpdatesPayment() {
        var payment = org.petify.funding.model.Payment.builder()
                .id(2L)
                .status(org.petify.funding.model.PaymentStatus.SUCCEEDED)
                .amount(new BigDecimal("100"))
                .build();
        var donation = org.petify.funding.model.MonetaryDonation.builder()
                .id(1L)
                .shelterId(1L)
                .amount(new BigDecimal("100"))
                .status(org.petify.funding.model.DonationStatus.COMPLETED)
                .payments(java.util.List.of(payment))
                .build();

        when(donationRepository.findById(1L)).thenReturn(java.util.Optional.of(donation));
        when(donationRepository.save(org.mockito.Mockito.any())).thenAnswer(inv -> inv.getArgument(0));
        when(paymentRepository.save(org.mockito.Mockito.any())).thenAnswer(inv -> inv.getArgument(0));

        var response = donationService.refundDonation(1L, new BigDecimal("50"));

        org.assertj.core.api.Assertions.assertThat(response.getStatus())
                .isEqualTo(org.petify.funding.model.DonationStatus.REFUNDED);
        org.assertj.core.api.Assertions.assertThat(payment.getStatus())
                .isEqualTo(org.petify.funding.model.PaymentStatus.PARTIALLY_REFUNDED);
    }
}