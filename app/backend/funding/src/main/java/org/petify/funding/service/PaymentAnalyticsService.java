package org.petify.funding.service;

import org.petify.funding.dto.PaymentAnalyticsResponse;
import org.petify.funding.model.PaymentAnalytics;
import org.petify.funding.model.PaymentProvider;
import org.petify.funding.repository.PaymentAnalyticsRepository;
import org.petify.funding.repository.PaymentRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentAnalyticsService {

    private final PaymentAnalyticsRepository analyticsRepository;
    private final PaymentRepository paymentRepository;

    public List<PaymentAnalyticsResponse> getAnalytics(LocalDate startDate, LocalDate endDate, String provider) {
        List<PaymentAnalytics> analytics;

        if (provider != null && !provider.isEmpty()) {
            PaymentProvider paymentProvider = PaymentProvider.valueOf(provider.toUpperCase());
            analytics = analyticsRepository.findByDateBetweenAndProvider(startDate, endDate, paymentProvider);
        } else {
            analytics = analyticsRepository.findByDateBetween(startDate, endDate);
        }

        return analytics.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public Map<String, Object> getPaymentStatsSummary(int days) {
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(days);

        Instant startInstant = startDate.atStartOfDay().atZone(ZoneId.systemDefault()).toInstant();
        Instant endInstant = endDate.atTime(LocalTime.MAX).atZone(ZoneId.systemDefault()).toInstant();

        Map<String, Object> stats = new HashMap<>();

        List<Object[]> overallStats = paymentRepository.getPaymentStatistics(startInstant, endInstant);

        if (!overallStats.isEmpty()) {
            Object[] row = overallStats.get(0);
            stats.put("totalTransactions", row[0]);
            stats.put("successfulTransactions", row[1]);
            stats.put("failedTransactions", row[2]);
            stats.put("totalAmount", row[3]);
            stats.put("totalFees", row[4]);
            stats.put("successRate", calculateSuccessRate((Long) row[1], (Long) row[0]));
        }

        Map<String, Object> providerStats = new HashMap<>();
        for (PaymentProvider provider : PaymentProvider.values()) {
            List<Object[]> providerData = paymentRepository.getPaymentStatisticsByProvider(
                    startInstant, endInstant, provider);

            if (!providerData.isEmpty()) {
                Object[] row = providerData.get(0);
                Map<String, Object> providerInfo = new HashMap<>();
                providerInfo.put("totalTransactions", row[0]);
                providerInfo.put("successfulTransactions", row[1]);
                providerInfo.put("totalAmount", row[2]);
                providerInfo.put("successRate", calculateSuccessRate((Long) row[1], (Long) row[0]));
                providerStats.put(provider.name().toLowerCase(), providerInfo);
            }
        }
        stats.put("providerBreakdown", providerStats);

        List<Map<String, Object>> dailyTrends = new ArrayList<>();
        for (int i = days - 1; i >= 0; i--) {
            LocalDate date = endDate.minusDays(i);
            Instant dayStart = date.atStartOfDay().atZone(ZoneId.systemDefault()).toInstant();
            Instant dayEnd = date.atTime(LocalTime.MAX).atZone(ZoneId.systemDefault()).toInstant();

            List<Object[]> dailyStats = paymentRepository.getPaymentStatistics(dayStart, dayEnd);

            Map<String, Object> dayStats = new HashMap<>();
            dayStats.put("date", date);

            if (!dailyStats.isEmpty()) {
                Object[] row = dailyStats.get(0);
                dayStats.put("transactions", row[0]);
                dayStats.put("amount", row[3]);
                dayStats.put("successRate", calculateSuccessRate((Long) row[1], (Long) row[0]));
            } else {
                dayStats.put("transactions", 0);
                dayStats.put("amount", BigDecimal.ZERO);
                dayStats.put("successRate", BigDecimal.ZERO);
            }

            dailyTrends.add(dayStats);
        }
        stats.put("dailyTrends", dailyTrends);

        Map<String, Object> currencyStats = paymentRepository.getPaymentStatsByCurrency(startInstant, endInstant);
        stats.put("currencyBreakdown", currencyStats);

        Map<String, Object> methodStats = paymentRepository.getPaymentStatsByMethod(startInstant, endInstant);
        stats.put("methodBreakdown", methodStats);

        return stats;
    }

    @Scheduled(cron = "0 0 1 * * ?")
    @Transactional
    public void generateDailyAnalytics() {
        LocalDate yesterday = LocalDate.now().minusDays(1);
        log.info("Generating analytics for {}", yesterday);

        for (PaymentProvider provider : PaymentProvider.values()) {
            generateAnalyticsForDate(yesterday, provider);
        }

        log.info("Daily analytics generation completed");
    }

    @Transactional
    public void generateAnalyticsForDate(LocalDate date, PaymentProvider provider) {
        Optional<PaymentAnalytics> existing = analyticsRepository
                .findByDateAndProvider(date, provider);

        if (existing.isPresent()) {
            log.debug("Analytics already exist for {} and {}", date, provider);
            return;
        }

        Instant startOfDay = date.atStartOfDay().atZone(ZoneId.systemDefault()).toInstant();
        Instant endOfDay = date.atTime(LocalTime.MAX).atZone(ZoneId.systemDefault()).toInstant();

        List<Object[]> stats = paymentRepository.getPaymentStatisticsByProvider(
                startOfDay, endOfDay, provider);

        if (stats.isEmpty()) {
            log.debug("No payments found for {} and {}", date, provider);
            return;
        }

        Object[] row = stats.get(0);

        PaymentAnalytics analytics = PaymentAnalytics.builder()
                .date(date)
                .provider(provider)
                .totalTransactions(((Long) row[0]).intValue())
                .successfulTransactions(((Long) row[1]).intValue())
                .failedTransactions(((Long) row[0]).intValue() - ((Long) row[1]).intValue())
                .totalAmount((BigDecimal) row[2])
                .totalFees(calculateTotalFees(startOfDay, endOfDay, provider))
                .successRate(calculateSuccessRate((Long) row[1], (Long) row[0]))
                .averageTransactionAmount(((BigDecimal) row[2]).divide(
                        new BigDecimal((Long) row[0]), 2, RoundingMode.HALF_UP))
                .build();

        analyticsRepository.save(analytics);
        log.debug("Analytics saved for {} and {}", date, provider);
    }

    private BigDecimal calculateTotalFees(Instant startOfDay, Instant endOfDay,
                                          PaymentProvider provider) {
        List<BigDecimal> fees = paymentRepository.getFeeAmountsByDateRangeAndProvider(
                startOfDay, endOfDay, provider);

        return fees.stream()
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private PaymentAnalyticsResponse toResponse(PaymentAnalytics analytics) {
        return PaymentAnalyticsResponse.builder()
                .date(analytics.getDate())
                .provider(analytics.getProvider())
                .totalTransactions(analytics.getTotalTransactions())
                .successfulTransactions(analytics.getSuccessfulTransactions())
                .failedTransactions(analytics.getFailedTransactions())
                .totalAmount(analytics.getTotalAmount())
                .totalFees(analytics.getTotalFees())
                .successRate(analytics.getSuccessRate())
                .averageTransactionAmount(analytics.getAverageTransactionAmount())
                .build();
    }

    private BigDecimal calculateSuccessRate(Long successful, Long total) {
        if (total == null || total == 0) {
            return BigDecimal.ZERO;
        }
        return new BigDecimal(successful)
                .divide(new BigDecimal(total), 4, RoundingMode.HALF_UP)
                .multiply(new BigDecimal("100"));
    }
}
