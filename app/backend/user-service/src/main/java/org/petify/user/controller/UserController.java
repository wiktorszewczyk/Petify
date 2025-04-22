package org.petify.user.controller;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/users")
@Slf4j
public class UserController {

    /**
     * Publiczny endpoint - dostępny bez uwierzytelniania
     */
    @GetMapping("/public")
    public ResponseEntity<Map<String, String>> publicEndpoint() {
        log.info("Wywołano publiczny endpoint");

        Map<String, String> response = new HashMap<>();
        response.put("message", "To jest publiczny endpoint - dostępny bez uwierzytelniania");
        response.put("status", "success");

        return ResponseEntity.ok(response);
    }

    /**
     * Zabezpieczony endpoint - wymaga uwierzytelnienia
     */
    @GetMapping("/me")
    public ResponseEntity<Map<String, Object>> userInfo() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        // Sprawdź, czy użytkownik jest uwierzytelniony (nie jest anonimowy)
        if (authentication == null || !authentication.isAuthenticated() ||
                authentication instanceof AnonymousAuthenticationToken) {
            log.warn("Próba dostępu do /users/me bez uwierzytelnienia lub z uwierzytelnieniem anonimowym");

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Unauthorized");
            errorResponse.put("message", "Ten endpoint wymaga uwierzytelnienia");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        log.info("Wywołano zabezpieczony endpoint przez użytkownika: {}", authentication.getName());

        Map<String, Object> response = new HashMap<>();
        response.put("authenticated", true);
        response.put("username", authentication.getName());
        response.put("authorities", authentication.getAuthorities());

        // Jeśli to uwierzytelnienie JWT, dodajemy więcej informacji
        if (authentication instanceof JwtAuthenticationToken) {
            JwtAuthenticationToken jwtAuth = (JwtAuthenticationToken) authentication;
            response.put("token_info", jwtAuth.getTokenAttributes());
        } else {
            log.warn("Uwierzytelnienie nie jest typu JwtAuthenticationToken: {}", authentication.getClass().getName());
            response.put("auth_type", authentication.getClass().getName());
        }

        return ResponseEntity.ok(response);
    }

    /**
     * Endpoint wymagający uprawnień administratora
     */
    @GetMapping("/admin")
    public ResponseEntity<Map<String, Object>> adminEndpoint() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        // Sprawdź, czy użytkownik jest uwierzytelniony (nie jest anonimowy)
        if (authentication == null || !authentication.isAuthenticated() ||
                authentication instanceof AnonymousAuthenticationToken) {
            log.warn("Próba dostępu do /users/admin bez uwierzytelnienia");

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Unauthorized");
            errorResponse.put("message", "Ten endpoint wymaga uwierzytelnienia");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        // Sprawdź, czy użytkownik ma uprawnienia administratora
        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));

        if (!isAdmin) {
            log.warn("Użytkownik {} próbował uzyskać dostęp do endpointu administratora bez wymaganych uprawnień",
                    authentication.getName());

            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Forbidden");
            errorResponse.put("message", "Ten endpoint wymaga uprawnień administratora");
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(errorResponse);
        }

        log.info("Wywołano endpoint administratora przez użytkownika: {}", authentication.getName());

        Map<String, Object> response = new HashMap<>();
        response.put("message", "Masz dostęp do funkcji administratora");
        response.put("status", "success");
        response.put("username", authentication.getName());

        return ResponseEntity.ok(response);
    }

    /**
     * Endpoint diagnostyczny - wyświetla nagłówki żądania
     */
    @GetMapping("/headers")
    public ResponseEntity<Map<String, Object>> showHeaders(@RequestHeader Map<String, String> headers) {
        log.info("Wywołano endpoint diagnostyczny nagłówków");

        Map<String, Object> response = new HashMap<>();
        response.put("headers", headers);

        // Sprawdzamy i logujemy szczególnie nagłówek Authorization
        String authHeader = headers.get("authorization");
        if (authHeader != null) {
            log.info("Znaleziono nagłówek Authorization: {}",
                    authHeader.startsWith("Bearer ") ?
                            "Bearer " + authHeader.substring(7, Math.min(15, authHeader.length())) + "..." :
                            authHeader);

            response.put("authorization_present", true);

            // Sprawdź, czy token jest obecny w nagłówku
            if (authHeader.startsWith("Bearer ") && authHeader.length() > 7) {
                response.put("token_present", true);
            } else {
                response.put("token_present", false);
                response.put("warning", "Nagłówek Authorization nie zawiera poprawnego tokenu Bearer");
            }
        } else {
            log.warn("Brak nagłówka Authorization");
            response.put("authorization_present", false);
        }

        // Dodaj informacje o bieżącym uwierzytelnieniu
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated() &&
                !(authentication instanceof AnonymousAuthenticationToken)) {
            response.put("authenticated", true);
            response.put("auth_name", authentication.getName());
            response.put("auth_type", authentication.getClass().getName());
        } else {
            response.put("authenticated", false);
        }

        return ResponseEntity.ok(response);
    }
}