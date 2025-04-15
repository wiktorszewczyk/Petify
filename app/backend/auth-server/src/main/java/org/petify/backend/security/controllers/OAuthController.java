package org.petify.backend.security.controllers;

import org.petify.backend.security.repository.UserRepository;
import org.petify.backend.security.services.TokenService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * Kontroler obsługujący endpoints związane z OAuth2
 */
@RestController
@RequestMapping("/oauth2")
public class OAuthController {

    @Autowired
    private TokenService tokenService;

    @Autowired
    private UserRepository userRepository;

    /**
     * Inicjacja procesu logowania przez Google OAuth2
     * Spring Security obsłuży przekierowanie do strony logowania Google
     *
     * @return Przekierowanie do autoryzacji Google
     */
    @GetMapping("/login/google")
    public String initiateGoogleLogin() {
        return "redirect:/oauth2/authorization/google";
    }

    /**
     * Pobieranie informacji o zalogowanym użytkowniku OAuth2
     *
     * @param principal Informacje o zalogowanym użytkowniku OAuth2
     * @return Mapa danych użytkownika
     */
    @GetMapping("/user-info")
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
    @GetMapping("/token")
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
}