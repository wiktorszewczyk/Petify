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

    @Test
    void getAnalyticsFiltersByProvider() {
        var analytics = java.util.List.of(
                org.petify.funding.model.PaymentAnalytics.builder()
                        .id(1L)
                        .provider(org.petify.funding.model.PaymentProvider.STRIPE)
                        .totalTransactions(1)
                        .build());

        when(analyticsRepository.findByDateBetweenAndProvider(any(), any(), any()))
                .thenReturn(analytics);

        var result = service.getAnalytics(java.time.LocalDate.now(), java.time.LocalDate.now(), "stripe");

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getProvider()).isEqualTo(org.petify.funding.model.PaymentProvider.STRIPE);
    }

    @Test
    void getAnalyticsWithoutProviderReturnsAll() {
        var analytics = java.util.List.of(
                org.petify.funding.model.PaymentAnalytics.builder()
                        .id(2L)
                        .provider(org.petify.funding.model.PaymentProvider.PAYU)
                        .totalTransactions(2)
                        .build());

        when(analyticsRepository.findByDateBetween(any(), any())).thenReturn(analytics);

        var result = service.getAnalytics(java.time.LocalDate.now(), java.time.LocalDate.now(), null);

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getProvider()).isEqualTo(org.petify.funding.model.PaymentProvider.PAYU);
    }

    @Test
    void generateAnalyticsForDateDoesNothingWhenExisting() {
        var existing = java.util.Optional.of(org.petify.funding.model.PaymentAnalytics.builder().id(1L).build());
        when(analyticsRepository.findByDateAndProvider(any(), any())).thenReturn(existing);

        service.generateAnalyticsForDate(java.time.LocalDate.now(), org.petify.funding.model.PaymentProvider.STRIPE);

        org.mockito.Mockito.verifyNoMoreInteractions(analyticsRepository);
    }

    @Test
    void generateAnalyticsForDateSavesWhenStatsAvailable() {
        when(analyticsRepository.findByDateAndProvider(any(), any())).thenReturn(java.util.Optional.empty());
        when(paymentRepository.getPaymentStatisticsByProvider(any(), any(), any()))
                .thenReturn(Collections.singletonList(new Object[]{
                        1L, 1L, new BigDecimal("10")
                }));
        when(paymentRepository.getFeeAmountsByDateRangeAndProvider(any(), any(), any()))
                .thenReturn(java.util.List.of(new BigDecimal("1")));

        service.generateAnalyticsForDate(java.time.LocalDate.now(), org.petify.funding.model.PaymentProvider.PAYU);

        org.mockito.Mockito.verify(analyticsRepository).save(org.mockito.Mockito.any());
    }

    @Test
    void getPaymentStatsSummaryHandlesNoStats() {
        when(paymentRepository.getPaymentStatistics(any(), any())).thenReturn(java.util.Collections.emptyList());
        when(paymentRepository.getPaymentStatsByCurrency(any(), any())).thenReturn(java.util.Collections.emptyMap());
        when(paymentRepository.getPaymentStatsByMethod(any(), any())).thenReturn(java.util.Collections.emptyMap());

        Map<String, Object> result = service.getPaymentStatsSummary(1);

        assertThat(result.get("successRate")).isNull();
    }
}