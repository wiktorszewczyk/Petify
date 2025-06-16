package org.petify.funding.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.funding.repository.PaymentAnalyticsRepository;
import org.petify.funding.repository.PaymentRepository;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PaymentAnalyticsServiceTest {

    @Mock
    private PaymentAnalyticsRepository analyticsRepository;
    @Mock
    private PaymentRepository paymentRepository;
    @InjectMocks
    private PaymentAnalyticsService service;

    @Test
    void getPaymentStatsSummaryCalculatesSuccessRate() {
        List<Object[]> statsRow = Collections.singletonList(new Object[]{
                10L, 7L, 3L,
                new BigDecimal("100"),
                new BigDecimal("5")
        });
        when(paymentRepository.getPaymentStatistics(any(), any()))
                .thenReturn(statsRow);

        when(paymentRepository.getPaymentStatisticsByProvider(any(), any(), any()))
                .thenReturn(Collections.singletonList(new Object[]{
                        1L, 1L, new BigDecimal("10")
                }));
        when(paymentRepository.getPaymentStatsByCurrency(any(), any()))
                .thenReturn(Collections.<String, Object>emptyMap());
        when(paymentRepository.getPaymentStatsByMethod(any(), any()))
                .thenReturn(Collections.<String, Object>emptyMap());

        Map<String, Object> result = service.getPaymentStatsSummary(1);

        assertThat(result.get("successRate")).isEqualTo(new BigDecimal("70.0000"));
    }
}