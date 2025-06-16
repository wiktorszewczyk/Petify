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
}