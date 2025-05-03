package org.petify.backend.controllers;

import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.LoginRequestDTO;
import org.petify.backend.models.LoginResponseDTO;
import org.petify.backend.models.RegistrationDTO;
import org.petify.backend.repository.UserRepository;
import org.petify.backend.services.AuthenticationService;
import org.petify.backend.services.TokenService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
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
    public ResponseEntity<?> registerUser(@Valid @RequestBody RegistrationDTO registrationDTO) {
        try {
            ApplicationUser user = authenticationService.registerUser(registrationDTO);
            return ResponseEntity.status(HttpStatus.CREATED).body(user);
        } catch (IllegalArgumentException e) {
            Map<String, String> response = new HashMap<>();
            response.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        } catch (Exception e) {
            Map<String, String> response = new HashMap<>();
            response.put("error", "Registration failed: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PostMapping("/auth/login")
    public ResponseEntity<?> loginUser(@Valid @RequestBody LoginRequestDTO loginRequest) {
        LoginResponseDTO response = authenticationService.loginUser(loginRequest);

        if (response.getUser() == null) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Invalid credentials");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        return ResponseEntity.ok(response);
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
     * Endpointy dla OAuth2
     */

    /**
     * Inicjacja procesu logowania przez Google OAuth2
     * Spring Security obsłuży przekierowanie do strony logowania Google
     *
     * @return Przekierowanie do autoryzacji Google
     */
    @GetMapping("/auth/oauth2/google")
    public String initiateGoogleLogin() {
        return "redirect:/oauth2/authorization/google";
    }

    /**
     * Pobieranie informacji o zalogowanym użytkowniku OAuth2
     *
     * @param principal Informacje o zalogowanym użytkowniku OAuth2
     * @return Mapa danych użytkownika
     */
    @GetMapping("/auth/oauth2/user-info")
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
    @GetMapping("/auth/oauth2/token")
    public Map<String, String> getOAuth2Token(Authentication authentication) {
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
     * Endpoint do pobierania danych użytkownika
     *
     * @param authentication Obiekt uwierzytelnienia
     * @return Dane użytkownika
     */
    @GetMapping("/auth/user")
    public ResponseEntity<?> getUserData(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "User not authenticated");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        ApplicationUser user = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Remove sensitive information
        user.setPassword(null);

        return ResponseEntity.ok(user);
    }

    /**
     * Endpoint do aktualizacji danych użytkownika
     */
    @PutMapping("/auth/user")
    public ResponseEntity<?> updateUserData(
            Authentication authentication,
            @RequestBody ApplicationUser userData) {

        if (authentication == null || !authentication.isAuthenticated()) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "User not authenticated");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        try {
            ApplicationUser updatedUser = authenticationService.updateUserProfile(
                    authentication.getName(), userData);

            // Remove sensitive information
            updatedUser.setPassword(null);

            return ResponseEntity.ok(updatedUser);
        } catch (IllegalArgumentException e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to update user data: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Endpoint do usuwania konta użytkownika
     */
    @DeleteMapping("/auth/user")
    public ResponseEntity<?> deleteUser(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "User not authenticated");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        try {
            authenticationService.deleteUserAccount(authentication.getName());

            Map<String, String> response = new HashMap<>();
            response.put("message", "User account successfully deleted");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to delete user account: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
}