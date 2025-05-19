package org.petify.backend.security.controllers;

import org.petify.backend.security.models.ApplicationUser;
import org.petify.backend.security.models.LoginResponseDTO;
import org.petify.backend.security.models.RegistrationDTO;
import org.petify.backend.security.repository.UserRepository;
import org.petify.backend.security.services.AuthenticationService;
import org.petify.backend.security.services.TokenService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * Kontroler obsługujący wszystkie endpointy związane z autoryzacją i uwierzytelnianiem,
 * zarówno przez formularz logowania jak i przez OAuth2
 */
@RestController
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class AuthenticationController {

    @Autowired
    private AuthenticationService authenticationService;

    @Autowired
    private TokenService tokenService;

    @Autowired
    private UserRepository userRepository;

    /**
     * Standardowe endpointy autoryzacyjne
     */
    @PostMapping("/auth/register")
    public ApplicationUser registerUser(@RequestBody RegistrationDTO body) {
        return authenticationService.registerUser(body.getUsername(), body.getPassword());
    }

    @PostMapping("/auth/login")
    public LoginResponseDTO loginUser(@RequestBody RegistrationDTO body) {
        return authenticationService.loginUser(body.getUsername(), body.getPassword());
    }

    /**
     * Endpoint do weryfikacji tokenu JWT
     *
     * @param authHeader Nagłówek Authorization z tokenem JWT
     * @return Status weryfikacji tokenu
     */
    @PostMapping("/auth/token/validate")
    public ResponseEntity<?> validateToken(@RequestHeader("Authorization") String authHeader) {
        try {
            // Wyodrębnij token z nagłówka Bearer
            String token = authHeader.substring(7); // Usuń "Bearer " z początku

            // Sprawdź czy token jest poprawny
            var jwt = tokenService.validateJwt(token);

            // Jeśli dotarliśmy tutaj, token jest poprawny
            Map<String, Object> response = new HashMap<>();
            response.put("valid", true);
            response.put("subject", jwt.getSubject());
            response.put("expires", jwt.getExpiresAt());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("valid", false);
            response.put("error", e.getMessage());

            return ResponseEntity.status(401).body(response);
        }
    }

    /**
     * Inicjacja procesu logowania przez Google OAuth2
     * Spring Security obsłuży przekierowanie do strony logowania Google
     *
     * @return Przekierowanie do autoryzacji Google
     */
    @GetMapping("/oauth2/login/google")
    public String initiateGoogleLogin() {
        return "redirect:/oauth2/authorization/google";
    }

    /**
     * Pobieranie informacji o zalogowanym użytkowniku OAuth2
     *
     * @param principal Informacje o zalogowanym użytkowniku OAuth2
     * @return Mapa danych użytkownika
     */
    @GetMapping("/oauth2/user-info")
    public Map<String, Object> getUserInfo(@AuthenticationPrincipal OAuth2User principal) {
        Map<String, Object> userInfo = new HashMap<>();

        if (principal != null) {
            userInfo.put("name", principal.getAttribute("name"));
            userInfo.put("email", principal.getAttribute("email"));
            userInfo.put("picture", principal.getAttribute("picture"));
            userInfo.put("locale", principal.getAttribute("locale"));
        }

        return userInfo;
    }

    /**
     * Generowanie tokenu JWT dla zalogowanego użytkownika OAuth2
     *
     * @param authentication Obiekt uwierzytelnienia
     * @return Mapa zawierająca token JWT lub informację o błędzie
     */
    @GetMapping("/oauth2/token")
    public Map<String, String> getToken(Authentication authentication) {
        Map<String, String> response = new HashMap<>();

        if (authentication != null && authentication.isAuthenticated()) {
            String token = tokenService.generateJwt(authentication);
            response.put("token", token);
        } else {
            response.put("error", "Użytkownik nie jest uwierzytelniony");
        }

        return response;
    }

    /**
     * Obsługa udanego logowania przez OAuth2 (np. Google)
     *
     * @param token Token JWT przekazany z handlera sukcesu logowania OAuth2
     * @param oauth2User Informacje o zalogowanym użytkowniku OAuth2
     * @return Dane użytkownika i token JWT
     */
    @GetMapping("/auth/oauth2/success")
    public ResponseEntity<Map<String, Object>> oauthLoginSuccess(
            @RequestParam(required = false) String token,
            @AuthenticationPrincipal OAuth2User oauth2User) {

        // Jeśli token nie został przekazany, spróbuj pobrać go z uwierzytelnionego użytkownika
        if (token == null || token.isEmpty()) {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth != null) {
                token = tokenService.generateJwt(auth);
            }
        }

        // Wyciągnij email, aby znaleźć naszego wewnętrznego użytkownika
        String email = oauth2User.getAttribute("email");
        if (email == null) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("error", "Email nie został znaleziony w odpowiedzi od dostawcy OAuth2");
            return ResponseEntity.badRequest().body(errorResponse);
        }

        ApplicationUser user = userRepository.findByUsername(email)
                .orElseThrow(() -> new RuntimeException("Nie znaleziono użytkownika"));

        // Utwórz odpowiedź z informacjami o użytkowniku i tokenem
        Map<String, Object> response = new HashMap<>();
        response.put("user", user);
        response.put("jwt", token);

        return ResponseEntity.ok(response);
    }

    /**
     * Obsługa błędu logowania przez OAuth2
     *
     * @return Informacja o błędzie
     */
    @GetMapping("/auth/oauth2/error")
    public ResponseEntity<Map<String, String>> oauthLoginError() {
        Map<String, String> response = new HashMap<>();
        response.put("error", "Uwierzytelnianie OAuth2 nie powiodło się");
        return ResponseEntity.badRequest().body(response);
    }

    /**
     * Endpoint statusowy dla diagnostyki
     *
     * @return Status auth service
     */
    @GetMapping("/auth/status")
    public ResponseEntity<Map<String, String>> getStatus() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("service", "auth-service");
        response.put("timestamp", String.valueOf(System.currentTimeMillis()));
        return ResponseEntity.ok(response);
    }
}
