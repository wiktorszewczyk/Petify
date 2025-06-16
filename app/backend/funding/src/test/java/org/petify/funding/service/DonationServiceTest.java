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
}