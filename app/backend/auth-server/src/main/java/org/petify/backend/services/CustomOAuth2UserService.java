package org.petify.backend.services;

import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.OAuth2Provider;
import org.petify.backend.models.Role;
import org.petify.backend.repository.OAuth2ProviderRepository;
import org.petify.backend.repository.RoleRepository;
import org.petify.backend.repository.UserRepository;

import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.user.DefaultOAuth2User;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

@Service
public class CustomOAuth2UserService extends DefaultOAuth2UserService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final OAuth2ProviderRepository oauth2ProviderRepository;
    private final PasswordEncoder passwordEncoder;
    private final AchievementService achievementService;

    public CustomOAuth2UserService(
            UserRepository userRepository,
            RoleRepository roleRepository,
            OAuth2ProviderRepository oauth2ProviderRepository,
            PasswordEncoder passwordEncoder,
            AchievementService achievementService) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.oauth2ProviderRepository = oauth2ProviderRepository;
        this.passwordEncoder = passwordEncoder;
        this.achievementService = achievementService;
    }

    @Override
    @Transactional
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        OAuth2User oauth2User = super.loadUser(userRequest);

        String providerId = userRequest.getClientRegistration().getRegistrationId();
        String providerUserId = oauth2User.getAttribute("sub");

        String email = oauth2User.getAttribute("email");
        String name = oauth2User.getAttribute("name");

        Optional<OAuth2Provider> existingProvider =
                oauth2ProviderRepository.findByProviderIdAndProviderUserId(providerId, providerUserId);

        ApplicationUser user;

        if (existingProvider.isPresent()) {
            user = existingProvider.get().getUser();

            existingProvider.get().setEmail(email);
            existingProvider.get().setName(name);
            oauth2ProviderRepository.save(existingProvider.get());
        } else {
            String username = (email != null) ? email : name + "_" + UUID.randomUUID().toString().substring(0, 8);

            Optional<ApplicationUser> existingUser = userRepository.findByUsername(username);

            if (existingUser.isPresent()) {
                user = existingUser.get();
            } else {
                Role userRole = roleRepository.findByAuthority("USER")
                        .orElseThrow(() -> new RuntimeException("USER role not found"));

                Set<Role> authorities = new HashSet<>();
                authorities.add(userRole);

                user = new ApplicationUser();
                user.setUsername(username);
                user.setEmail(email);

                if (name != null) {
                    String[] nameParts = name.split(" ", 2);
                    user.setFirstName(nameParts[0]);
                    if (nameParts.length > 1) {
                        user.setLastName(nameParts[1]);
                    }
                }

                user.setPassword(passwordEncoder.encode(UUID.randomUUID().toString()));
                user.setAuthorities(authorities);

                user = userRepository.save(user);

                achievementService.initializeUserAchievements(user);

                OAuth2Provider provider = new OAuth2Provider(
                        providerId,
                        providerUserId,
                        user,
                        email,
                        name
                );
                oauth2ProviderRepository.save(provider);
            }
        }

        Collection<SimpleGrantedAuthority> authorities = new ArrayList<>();
        user.getAuthorities().forEach(role -> {
            String authority = role.getAuthority();
            if (!authority.startsWith("ROLE_")) {
                authority = "ROLE_" + authority;
            }
            authorities.add(new SimpleGrantedAuthority(authority));
        });

        Map<String, Object> attributes = new HashMap<>(oauth2User.getAttributes());
        attributes.put("userId", user.getUserId());

        return new DefaultOAuth2User(
                authorities,
                attributes,
                "email"
        );
    }
}
