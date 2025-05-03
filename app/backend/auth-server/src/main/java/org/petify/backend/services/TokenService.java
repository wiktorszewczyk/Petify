package org.petify.backend.services;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

/**
 * Serwis do obsługi tokenów JWT - generowanie i walidacja
 */
@Service
public class TokenService {

    @Autowired
    private JwtEncoder jwtEncoder;

    @Autowired
    private JwtDecoder jwtDecoder;

    /**
     * Generuje token JWT na podstawie obiektu Authentication
     */
    public String generateJwt(Authentication auth) {
        Instant now = Instant.now();
        Instant expiryTime = now.plus(24, ChronoUnit.HOURS);  // Token ważny 24h

        // Zbierz wszystkie uprawnienia użytkownika
        String scope = auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.joining(" "));

        // Buduj podstawowe claims dla tokenu
        JwtClaimsSet.Builder claimsBuilder = JwtClaimsSet.builder()
                .issuer("http://localhost:9000")
                .issuedAt(now)
                .expiresAt(expiryTime)
                .subject(auth.getName())
                .claim("roles", scope);

        // Dodaj dodatkowe informacje dla użytkowników OAuth2
        if (auth.getPrincipal() instanceof OAuth2User) {
            addOAuth2Claims(claimsBuilder, (OAuth2User) auth.getPrincipal());
        } else {
            claimsBuilder.claim("auth_method", "form");
        }

        // Zakoduj i zwróć token
        return jwtEncoder.encode(JwtEncoderParameters.from(claimsBuilder.build())).getTokenValue();
    }

    /**
     * Dodaje claims specyficzne dla użytkowników OAuth2
     */
    private void addOAuth2Claims(JwtClaimsSet.Builder claimsBuilder, OAuth2User oauth2User) {
        // Dodaj user ID, jeśli dostępne
        if (oauth2User.getAttribute("userId") != null) {
            claimsBuilder.claim("userId", oauth2User.getAttribute("userId"));
        }

        // Dodaj email, jeśli dostępny
        if (oauth2User.getAttribute("email") != null) {
            claimsBuilder.claim("email", oauth2User.getAttribute("email"));
        }

        // Dodaj imię, jeśli dostępne
        if (oauth2User.getAttribute("name") != null) {
            claimsBuilder.claim("name", oauth2User.getAttribute("name"));
        }

        // Oznacz metodę uwierzytelniania
        claimsBuilder.claim("auth_method", "oauth2");
    }

    /**
     * Waliduje token JWT i zwraca zdekodowane dane
     */
    public org.springframework.security.oauth2.jwt.Jwt validateJwt(String token) {
        return jwtDecoder.decode(token);
    }
}