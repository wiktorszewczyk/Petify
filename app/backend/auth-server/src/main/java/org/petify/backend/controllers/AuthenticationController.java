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
     * Endpoint do pobierania profilu użytkownika
     *
     * @param authentication Obiekt uwierzytelnienia
     * @return Dane użytkownika
     */
    @GetMapping("/auth/profile")
    public ResponseEntity<?> getUserProfile(Authentication authentication) {
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
     * Endpoint do aktualizacji profilu użytkownika
     *
     * @param authentication Obiekt uwierzytelnienia
     * @param userData Dane do aktualizacji
     * @return Zaktualizowane dane użytkownika
     */
    @PutMapping("/auth/profile")
    public ResponseEntity<?> updateUserProfile(
            Authentication authentication,
            @RequestBody Map<String, Object> userData) {

        if (authentication == null || !authentication.isAuthenticated()) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "User not authenticated");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        ApplicationUser user = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Update fields that are allowed to be updated
        // Note: We don't allow username or password to be updated through this endpoint
        if (userData.containsKey("firstName")) {
            user.setFirstName((String) userData.get("firstName"));
        }
        if (userData.containsKey("lastName")) {
            user.setLastName((String) userData.get("lastName"));
        }
        if (userData.containsKey("phoneNumber")) {
            user.setPhoneNumber((String) userData.get("phoneNumber"));
        }

        ApplicationUser updatedUser = userRepository.save(user);
        updatedUser.setPassword(null); // Remove sensitive information

        return ResponseEntity.ok(updatedUser);
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

//    /**
//     * Endpoint do zmiany hasła
//     *
//     * @param authentication Obiekt uwierzytelnienia
//     * @param passwordData Mapa zawierająca stare i nowe hasło
//     * @return Status operacji
//     */
//    @PostMapping("/auth/change-password")
//    public ResponseEntity<?> changePassword(
//            Authentication authentication,
//            @RequestBody Map<String, String> passwordData) {
//
//        if (authentication == null || !authentication.isAuthenticated()) {
//            Map<String, String> errorResponse = new HashMap<>();
//            errorResponse.put("error", "User not authenticated");
//            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
//        }
//
//        String currentPassword = passwordData.get("currentPassword");
//        String newPassword = passwordData.get("newPassword");
//
//        if (currentPassword == null || newPassword == null) {
//            Map<String, String> errorResponse = new HashMap<>();
//            errorResponse.put("error", "Current password and new password are required");
//            return ResponseEntity.badRequest().body(errorResponse);
//        }
//
//        try {
//            authenticationService.changePassword(authentication.getName(), currentPassword, newPassword);
//
//            Map<String, String> response = new HashMap<>();
//            response.put("message", "Password successfully changed");
//            return ResponseEntity.ok(response);
//        } catch (Exception e) {
//            Map<String, String> errorResponse = new HashMap<>();
//            errorResponse.put("error", e.getMessage());
//            return ResponseEntity.badRequest().body(errorResponse);
//        }
//    }
//
//    /**
//     * Endpoint do resetowania hasła - inicjacja procesu
//     *
//     * @param requestData Mapa zawierająca email lub telefon użytkownika
//     * @return Status operacji
//     */
//    @PostMapping("/auth/forgot-password")
//    public ResponseEntity<?> initPasswordReset(@RequestBody Map<String, String> requestData) {
//        String identifier = requestData.get("loginIdentifier");
//
//        if (identifier == null || identifier.isEmpty()) {
//            Map<String, String> errorResponse = new HashMap<>();
//            errorResponse.put("error", "Email or phone number is required");
//            return ResponseEntity.badRequest().body(errorResponse);
//        }
//
//        try {
//            authenticationService.initiatePasswordReset(identifier);
//
//            Map<String, String> response = new HashMap<>();
//            response.put("message", "Password reset initiated. Check your email or phone for instructions.");
//            return ResponseEntity.ok(response);
//        } catch (Exception e) {
//            Map<String, String> errorResponse = new HashMap<>();
//            errorResponse.put("error", e.getMessage());
//            return ResponseEntity.badRequest().body(errorResponse);
//        }
//    }
//
//    /**
//     * Endpoint do resetowania hasła - finalizacja procesu
//     *
//     * @param resetData Mapa zawierająca token resetujący i nowe hasło
//     * @return Status operacji
//     */
//    @PostMapping("/auth/reset-password")
//    public ResponseEntity<?> completePasswordReset(@RequestBody Map<String, String> resetData) {
//        String token = resetData.get("token");
//        String newPassword = resetData.get("newPassword");
//
//        if (token == null || newPassword == null) {
//            Map<String, String> errorResponse = new HashMap<>();
//            errorResponse.put("error", "Reset token and new password are required");
//            return ResponseEntity.badRequest().body(errorResponse);
//        }
//
//        try {
//            authenticationService.completePasswordReset(token, newPassword);
//
//            Map<String, String> response = new HashMap<>();
//            response.put("message", "Password has been reset successfully");
//            return ResponseEntity.ok(response);
//        } catch (Exception e) {
//            Map<String, String> errorResponse = new HashMap<>();
//            errorResponse.put("error", e.getMessage());
//            return ResponseEntity.badRequest().body(errorResponse);
//        }
//    }
}