package org.petify.user.controller;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * Kontroler diagnostyczny do identyfikacji problemów z routingiem i przekazywaniem żądań
 */
@RestController
@Slf4j
public class DiagnosticController {

    /**
     * Endpoint do przechwytywania wszystkich żądań, które nie zostały obsłużone przez inne kontrolery
     */
    @GetMapping("/**")
    public ResponseEntity<Map<String, Object>> catchAll(
            HttpServletRequest request,
            @RequestHeader Map<String, String> headers) {

        log.info("Przechwycono nieobsłużone żądanie: {} {}", request.getMethod(), request.getRequestURI());

        Map<String, Object> response = new HashMap<>();
        response.put("message", "Diagnostyka żądania");
        response.put("method", request.getMethod());
        response.put("uri", request.getRequestURI());
        response.put("url", request.getRequestURL().toString());
        response.put("query", request.getQueryString());
        response.put("remote_addr", request.getRemoteAddr());
        response.put("server_name", request.getServerName());
        response.put("server_port", request.getServerPort());

        // Dodaj wszystkie nagłówki
        response.put("headers", headers);

        // Dodaj wszystkie parametry
        Map<String, String[]> params = request.getParameterMap();
        if (params != null && !params.isEmpty()) {
            response.put("parameters", params);
        }

        // Sprawdź, czy żądanie przeszło przez gateway
        if (headers.containsKey("x-forwarded-host") || headers.containsKey("x-forwarded-for")) {
            response.put("forwarded_request", true);
        } else {
            response.put("forwarded_request", false);
        }

        log.debug("Szczegóły żądania: {}", response);

        return ResponseEntity.ok(response);
    }

    /**
     * Specjalny endpoint diagnostyczny dostępny pod głównym URL
     */
    @GetMapping("/")
    public ResponseEntity<Map<String, Object>> rootDiagnostic(
            HttpServletRequest request,
            @RequestHeader Map<String, String> headers) {

        log.info("Wywołano główny endpoint diagnostyczny");

        Map<String, Object> response = new HashMap<>();
        response.put("service", "user-service");
        response.put("status", "up");
        response.put("timestamp", System.currentTimeMillis());
        response.put("request_uri", request.getRequestURI());
        response.put("server_info", request.getServerName() + ":" + request.getServerPort());

        // Dodaj informacje o nagłówkach (z uwzględnieniem bezpieczeństwa)
        Map<String, String> safeHeaders = new HashMap<>();
        headers.forEach((key, value) -> {
            if (key.toLowerCase().contains("authorization")) {
                safeHeaders.put(key, "Bearer [MASKED]");
            } else {
                safeHeaders.put(key, value);
            }
        });
        response.put("headers", safeHeaders);

        log.debug("Diagnostyka głównego endpointu: {}", response);

        return ResponseEntity.ok(response);
    }
}
