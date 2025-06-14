package org.petify.backend.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class TokenService {

    @Autowired
    private JwtEncoder jwtEncoder;

    @Autowired
    private JwtDecoder jwtDecoder;

    public String generateJwt(Authentication auth) {
        Instant now = Instant.now();
        Instant expiryTime = now.plus(24, ChronoUnit.HOURS);

        List<String> roles = auth.getAuthorities().stream()
                .map(authority -> {
                    String role = authority.getAuthority();
                    return role.startsWith("ROLE_") ? role.substring(5) : role;
                })
                .collect(Collectors.toList());

        JwtClaimsSet.Builder claimsBuilder = JwtClaimsSet.builder()
                .issuer("http://localhost:9000")
                .issuedAt(now)
                .expiresAt(expiryTime)
                .subject(auth.getName())
                .claim("roles", roles);

        if (auth.getPrincipal() instanceof OAuth2User) {
            addOAuth2Claims(claimsBuilder, (OAuth2User) auth.getPrincipal());
        } else {
            claimsBuilder.claim("auth_method", "form");
        }

        return jwtEncoder.encode(JwtEncoderParameters.from(claimsBuilder.build())).getTokenValue();
    }

    private void addOAuth2Claims(JwtClaimsSet.Builder claimsBuilder, OAuth2User oauth2User) {
        if (oauth2User.getAttribute("userId") != null) {
            claimsBuilder.claim("userId", oauth2User.getAttribute("userId"));
        }

        if (oauth2User.getAttribute("email") != null) {
            claimsBuilder.claim("email", oauth2User.getAttribute("email"));
        }

        if (oauth2User.getAttribute("name") != null) {
            claimsBuilder.claim("name", oauth2User.getAttribute("name"));
        }

        claimsBuilder.claim("auth_method", "oauth2");
    }

    public org.springframework.security.oauth2.jwt.Jwt validateJwt(String token) {
        return jwtDecoder.decode(token);
    }
}
