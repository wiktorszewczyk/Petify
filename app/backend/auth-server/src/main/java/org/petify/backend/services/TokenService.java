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
 * Service for JWT token operations - generation and validation
 */
@Service
public class TokenService {

    @Autowired
    private JwtEncoder jwtEncoder;

    @Autowired
    private JwtDecoder jwtDecoder;

    /**
     * Generates a JWT token based on an Authentication object
     */
    public String generateJwt(Authentication auth) {
        Instant now = Instant.now();
        Instant expiryTime = now.plus(24, ChronoUnit.HOURS);  // Token valid for 24h

        // Collect all user permissions
        String scope = auth.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.joining(" "));

        // Build basic claims for the token
        JwtClaimsSet.Builder claimsBuilder = JwtClaimsSet.builder()
                .issuer("http://localhost:9000")
                .issuedAt(now)
                .expiresAt(expiryTime)
                .subject(auth.getName())
                .claim("roles", scope);

        // Add additional information for OAuth2 users
        if (auth.getPrincipal() instanceof OAuth2User) {
            addOAuth2Claims(claimsBuilder, (OAuth2User) auth.getPrincipal());
        } else {
            claimsBuilder.claim("auth_method", "form");
        }

        // Encode and return the token
        return jwtEncoder.encode(JwtEncoderParameters.from(claimsBuilder.build())).getTokenValue();
    }

    /**
     * Adds OAuth2-specific claims to the token
     */
    private void addOAuth2Claims(JwtClaimsSet.Builder claimsBuilder, OAuth2User oauth2User) {
        // Add user ID if available
        if (oauth2User.getAttribute("userId") != null) {
            claimsBuilder.claim("userId", oauth2User.getAttribute("userId"));
        }

        // Add email if available
        if (oauth2User.getAttribute("email") != null) {
            claimsBuilder.claim("email", oauth2User.getAttribute("email"));
        }

        // Add name if available
        if (oauth2User.getAttribute("name") != null) {
            claimsBuilder.claim("name", oauth2User.getAttribute("name"));
        }

        // Mark authentication method
        claimsBuilder.claim("auth_method", "oauth2");
    }

    /**
     * Validates a JWT token and returns decoded data
     */
    public org.springframework.security.oauth2.jwt.Jwt validateJwt(String token) {
        return jwtDecoder.decode(token);
    }
}