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
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/auth")
@CrossOrigin("*")
public class AuthenticationController {

    @Autowired
    private AuthenticationService authenticationService;

    @Autowired
    private TokenService tokenService;

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/register")
    public ApplicationUser registerUser(@RequestBody RegistrationDTO body) {
        return authenticationService.registerUser(body.getUsername(), body.getPassword());
    }

    @PostMapping("/login")
    public LoginResponseDTO loginUser(@RequestBody RegistrationDTO body) {
        return authenticationService.loginUser(body.getUsername(), body.getPassword());
    }

    /**
     * Obsługa udanego logowania przez OAuth2 (np. Google)
     *
     * @param token Token JWT przekazany z handlera sukcesu logowania OAuth2
     * @param oauth2User Informacje o zalogowanym użytkowniku OAuth2
     * @return Dane użytkownika i token JWT
     */
    @GetMapping("/oauth2/success")
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
    @GetMapping("/oauth2/error")
    public ResponseEntity<Map<String, String>> oauthLoginError() {
        Map<String, String> response = new HashMap<>();
        response.put("error", "Uwierzytelnianie OAuth2 nie powiodło się");
        return ResponseEntity.badRequest().body(response);
    }

    /**
     * Pobieranie informacji o zalogowanym użytkowniku OAuth2
     *
     * @param oauth2User Informacje o zalogowanym użytkowniku OAuth2
     * @return Atrybuty użytkownika OAuth2
     */
    @GetMapping("/oauth2/user")
    public ResponseEntity<Map<String, Object>> getOAuthUserInfo(@AuthenticationPrincipal OAuth2User oauth2User) {
        return ResponseEntity.ok(oauth2User.getAttributes());
    }
}