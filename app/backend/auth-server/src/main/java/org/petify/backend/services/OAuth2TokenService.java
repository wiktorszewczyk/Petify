package org.petify.backend.services;

import org.petify.backend.dto.LoginResponseDTO;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.OAuth2Provider;
import org.petify.backend.models.Role;
import org.petify.backend.repository.OAuth2ProviderRepository;
import org.petify.backend.repository.RoleRepository;
import org.petify.backend.repository.UserRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class OAuth2TokenService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private OAuth2ProviderRepository oauth2ProviderRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private TokenService tokenService;

    public LoginResponseDTO exchangeGoogleToken(String accessToken) {
        Map<String, Object> googleUserInfo = verifyGoogleToken(accessToken);
        if (googleUserInfo == null) {
            throw new RuntimeException("Invalid Google access token");
        }

        ApplicationUser user = findOrCreateUserFromGoogle(googleUserInfo);

        Authentication authentication = createAuthenticationFromUser(user);

        String token = tokenService.generateJwt(authentication);

        return new LoginResponseDTO(user, token);
    }

    private Map<String, Object> verifyGoogleToken(String accessToken) {
        try {
            RestTemplate restTemplate = new RestTemplate();
            String googleApiUrl = "https://www.googleapis.com/oauth2/v2/userinfo?access_token=" + accessToken;

            @SuppressWarnings("unchecked")
            Map<String, Object> response = restTemplate.getForObject(googleApiUrl, Map.class);

            if (response != null && response.containsKey("email") && response.containsKey("id")) {
                return response;
            }

            return null;
        } catch (Exception e) {
            System.err.println("Error verifying Google token: " + e.getMessage());
            return null;
        }
    }

    @Transactional
    protected ApplicationUser findOrCreateUserFromGoogle(Map<String, Object> googleUserInfo) {
        String email = (String) googleUserInfo.get("email");
        String googleId = (String) googleUserInfo.get("id");
        String name = (String) googleUserInfo.get("name");

        Optional<OAuth2Provider> existingProvider =
                oauth2ProviderRepository.findByProviderIdAndProviderUserId("google", googleId);

        if (existingProvider.isPresent()) {
            final ApplicationUser user = existingProvider.get().getUser();

            existingProvider.get().setEmail(email);
            existingProvider.get().setName(name);
            oauth2ProviderRepository.save(existingProvider.get());

            return user;
        }

        final ApplicationUser user = userRepository.findByUsername(email)
                .orElseGet(() -> {
                    Role userRole = roleRepository.findByAuthority("USER")
                            .orElseThrow(() -> new RuntimeException("USER role not found"));
                    Set<Role> authorities = new HashSet<>();
                    authorities.add(userRole);
                    ApplicationUser u = new ApplicationUser();
                    u.setUsername(email);
                    u.setEmail(email);

                    if (name != null) {
                        String[] nameParts = name.split(" ", 2);
                        u.setFirstName(nameParts[0]);
                        if (nameParts.length > 1) {
                            u.setLastName(nameParts[1]);
                        }
                    }

                    u.setPassword(passwordEncoder.encode(UUID.randomUUID().toString()));
                    u.setAuthorities(authorities);

                    return userRepository.save(u);
                });
        OAuth2Provider provider = new OAuth2Provider(
                "google",
                googleId,
                user,
                email,
                name
        );
        oauth2ProviderRepository.save(provider);
        return user;
    }

    private Authentication createAuthenticationFromUser(ApplicationUser user) {
        List<SimpleGrantedAuthority> authorities = user.getAuthorities().stream()
                .map(role -> {
                    String authority = role.getAuthority();
                    if (!authority.startsWith("ROLE_")) {
                        authority = "ROLE_" + authority;
                    }
                    return new SimpleGrantedAuthority(authority);
                })
                .collect(Collectors.toList());

        return new UsernamePasswordAuthenticationToken(
                user.getUsername(),
                null,
                authorities
        );
    }
}
