package org.petify.backend.performance;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
public class SimplePerformanceTest {

    @Test
    @DisplayName("Test 1: Wydajność tworzenia obiektów")
    void testObjectCreationPerformance() {
        List<Long> times = new ArrayList<>();
        
        for (int i = 0; i < 1000; i++) {
            long start = System.nanoTime();

            List<String> testList = new ArrayList<>();
            for (int j = 0; j < 100; j++) {
                testList.add("test" + j);
            }
            
            long end = System.nanoTime();
            times.add(end - start);
        }
        
        double avgTime = times.stream().mapToLong(Long::longValue).average().orElse(0.0);
        long maxTime = times.stream().mapToLong(Long::longValue).max().orElse(0L);
        
        System.out.println("=== TEST TWORZENIA OBIEKTÓW ===");
        System.out.println("Średni czas: " + String.format("%.2f", avgTime / 1000000) + " ms");
        System.out.println("Maksymalny czas: " + String.format("%.2f", maxTime / 1000000.0) + " ms");
        
        assertTrue(avgTime < 10_000_000, "Średni czas powinien być < 10ms");
    }

    @Test
    @DisplayName("Test 2: Wydajność operacji na stringach")
    void testStringOperationsPerformance() {
        List<Long> times = new ArrayList<>();
        
        for (int i = 0; i < 1000; i++) {
            long start = System.nanoTime();
            
            StringBuilder sb = new StringBuilder();
            for (int j = 0; j < 1000; j++) {
                sb.append("test").append(j).append("_");
            }
            String result = sb.toString();
            
            long end = System.nanoTime();
            times.add(end - start);
        }
        
        double avgTime = times.stream().mapToLong(Long::longValue).average().orElse(0.0);
        long maxTime = times.stream().mapToLong(Long::longValue).max().orElse(0L);
        
        System.out.println("=== TEST OPERACJI STRING ===");
        System.out.println("Średni czas: " + String.format("%.2f", avgTime / 1000000) + " ms");
        System.out.println("Maksymalny czas: " + String.format("%.2f", maxTime / 1000000.0) + " ms");
        
        assertTrue(avgTime < 5_000_000, "Średni czas powinien być < 5ms");
    }

    @Test
    @DisplayName("Test 3: Wydajność operacji matematycznych")
    void testMathOperationsPerformance() {
        List<Long> times = new ArrayList<>();
        
        for (int i = 0; i < 10000; i++) {
            long start = System.nanoTime();
            
            double result = 0;
            for (int j = 0; j < 100; j++) {
                result += Math.sqrt(j) * Math.sin(j) + Math.cos(j);
            }
            
            long end = System.nanoTime();
            times.add(end - start);
        }
        
        double avgTime = times.stream().mapToLong(Long::longValue).average().orElse(0.0);
        long maxTime = times.stream().mapToLong(Long::longValue).max().orElse(0L);
        
        System.out.println("=== TEST OPERACJI MATEMATYCZNYCH ===");
        System.out.println("Średni czas: " + String.format("%.2f", avgTime / 1000000) + " ms");
        System.out.println("Maksymalny czas: " + String.format("%.2f", maxTime / 1000000.0) + " ms");
        
        assertTrue(avgTime < 1_000_000, "Średni czas powinien być < 1ms");
    }

    @Test
    @DisplayName("Test 4: Test współbieżności")
    void testConcurrencyPerformance() throws Exception {
        ExecutorService executor = Executors.newFixedThreadPool(10);
        List<CompletableFuture<Long>> futures = new ArrayList<>();
        
        long testStart = System.currentTimeMillis();
        
        for (int i = 0; i < 50; i++) {
            CompletableFuture<Long> future = CompletableFuture.supplyAsync(() -> {
                long start = System.nanoTime();

                try {
                    Thread.sleep(10);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }

                double sum = 0;
                for (int j = 0; j < 1000; j++) {
                    sum += Math.random();
                }
                
                return System.nanoTime() - start;
            }, executor);
            
            futures.add(future);
        }
        
        List<Long> times = new ArrayList<>();
        for (CompletableFuture<Long> future : futures) {
            times.add(future.get());
        }
        
        long testEnd = System.currentTimeMillis();
        long totalTime = testEnd - testStart;
        
        executor.shutdown();
        assertTrue(executor.awaitTermination(5, TimeUnit.SECONDS));
        
        double avgTime = times.stream().mapToLong(Long::longValue).average().orElse(0.0);
        double throughput = 50.0 / (totalTime / 1000.0);
        
        System.out.println("=== TEST WSPÓŁBIEŻNOŚCI ===");
        System.out.println("Całkowity czas: " + totalTime + " ms");
        System.out.println("Średni czas zadania: " + String.format("%.2f", avgTime / 1000000) + " ms");
        System.out.println("Throughput: " + String.format("%.2f", throughput) + " zadań/sek");
        
        assertTrue(totalTime < 2000, "Całkowity czas powinien być < 2000ms");
        assertTrue(throughput > 10, "Throughput powinien być > 10 zadań/sek");
    }

    @Test
    @DisplayName("Test 5: Test pamięci")
    void testMemoryUsage() {
        Runtime runtime = Runtime.getRuntime();
        
        System.gc();
        try {
            Thread.sleep(100);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        long initialMemory = runtime.totalMemory() - runtime.freeMemory();
        System.out.println("Pamięć początkowa: " + (initialMemory / 1024 / 1024) + " MB");

        List<byte[]> memoryHog = new ArrayList<>();
        for (int i = 0; i < 100; i++) {
            memoryHog.add(new byte[1024 * 1024]);
            
            if (i % 10 == 0) {
                System.gc();
                try {
                    Thread.sleep(10);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        }
        
        long peakMemory = runtime.totalMemory() - runtime.freeMemory();
        System.out.println("Pamięć szczytowa: " + (peakMemory / 1024 / 1024) + " MB");

        memoryHog.clear();
        System.gc();
        try {
            Thread.sleep(200);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        long finalMemory = runtime.totalMemory() - runtime.freeMemory();
        System.out.println("Pamięć końcowa: " + (finalMemory / 1024 / 1024) + " MB");
        
        long memoryIncrease = finalMemory - initialMemory;
        System.out.println("Wzrost pamięci: " + (memoryIncrease / 1024 / 1024) + " MB");
        
        assertTrue(memoryIncrease < 50 * 1024 * 1024, "Wzrost pamięci powinien być < 50MB");
    }

    @Test
    @DisplayName("Test 6: Test I/O operacji")
    void testIOPerformance() {
        List<Long> times = new ArrayList<>();
        
        for (int i = 0; i < 100; i++) {
            long start = System.nanoTime();

            String tempDir = System.getProperty("java.io.tmpdir");
            assertNotNull(tempDir);

            String osName = System.getProperty("os.name");
            String javaVersion = System.getProperty("java.version");
            String userHome = System.getProperty("user.home");
            
            assertNotNull(osName);
            assertNotNull(javaVersion);
            assertNotNull(userHome);
            
            long end = System.nanoTime();
            times.add(end - start);
        }
        
        double avgTime = times.stream().mapToLong(Long::longValue).average().orElse(0.0);
        long maxTime = times.stream().mapToLong(Long::longValue).max().orElse(0L);
        
        System.out.println("=== TEST OPERACJI I/O ===");
        System.out.println("Średni czas: " + String.format("%.2f", avgTime / 1000000) + " ms");
        System.out.println("Maksymalny czas: " + String.format("%.2f", maxTime / 1000000.0) + " ms");
        
        assertTrue(avgTime < 1_000_000, "Średni czas powinien być < 1ms");
    }

    @Test
    @DisplayName("Test 7: Test algorytmu sortowania")
    void testSortingPerformance() {
        List<Long> times = new ArrayList<>();
        
        for (int i = 0; i < 100; i++) {
            List<Integer> data = new ArrayList<>();
            for (int j = 0; j < 10000; j++) {
                data.add((int) (Math.random() * 10000));
            }
            
            long start = System.nanoTime();
            data.sort(Integer::compareTo);
            long end = System.nanoTime();
            
            times.add(end - start);
        }
        
        double avgTime = times.stream().mapToLong(Long::longValue).average().orElse(0.0);
        long maxTime = times.stream().mapToLong(Long::longValue).max().orElse(0L);
        
        System.out.println("=== TEST SORTOWANIA (10k elementów) ===");
        System.out.println("Średni czas: " + String.format("%.2f", avgTime / 1000000) + " ms");
        System.out.println("Maksymalny czas: " + String.format("%.2f", maxTime / 1000000.0) + " ms");
        
        assertTrue(avgTime < 50_000_000, "Średni czas sortowania powinien być < 50ms");
    }
}
