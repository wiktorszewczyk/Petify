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

import java.util.*;

@Service
public class CustomOAuth2UserService extends DefaultOAuth2UserService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final OAuth2ProviderRepository oAuth2ProviderRepository;
    private final PasswordEncoder passwordEncoder;

    public CustomOAuth2UserService(
            UserRepository userRepository,
            RoleRepository roleRepository,
            OAuth2ProviderRepository oAuth2ProviderRepository,
            PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.oAuth2ProviderRepository = oAuth2ProviderRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        OAuth2User oAuth2User = super.loadUser(userRequest);

        // Get OAuth2 provider data
        String providerId = userRequest.getClientRegistration().getRegistrationId();
        String providerUserId = oAuth2User.getAttribute("sub");

        // Get user data from OAuth response
        String email = oAuth2User.getAttribute("email");
        String name = oAuth2User.getAttribute("name");

        // Check if we've seen this user before
        Optional<OAuth2Provider> existingProvider =
                oAuth2ProviderRepository.findByProviderIdAndProviderUserId(providerId, providerUserId);

        ApplicationUser user;

        if (existingProvider.isPresent()) {
            // User has logged in before - get their data
            user = existingProvider.get().getUser();

            // Update user data if needed
            existingProvider.get().setEmail(email);
            existingProvider.get().setName(name);
            oAuth2ProviderRepository.save(existingProvider.get());
        } else {
            // This is a new OAuth2 user

            // Generate unique username based on email or name
            String username = (email != null) ? email : name + "_" + UUID.randomUUID().toString().substring(0, 8);

            // Check if user with this email already exists
            Optional<ApplicationUser> existingUser = userRepository.findByUsername(username);

            if (existingUser.isPresent()) {
                user = existingUser.get();
            } else {
                // Create new user
                Role userRole = roleRepository.findByAuthority("USER")
                        .orElseThrow(() -> new RuntimeException("USER role not found"));

                Set<Role> authorities = new HashSet<>();
                authorities.add(userRole);

                user = new ApplicationUser();
                user.setUsername(username);
                user.setEmail(email);

                // Set name if available (split into first/last name)
                if (name != null) {
                    String[] nameParts = name.split(" ", 2);
                    user.setFirstName(nameParts[0]);
                    if (nameParts.length > 1) {
                        user.setLastName(nameParts[1]);
                    }
                }

                // For OAuth2 users, set a secure random password they won't use
                user.setPassword(passwordEncoder.encode(UUID.randomUUID().toString()));
                user.setAuthorities(authorities);

                // Save user first to get ID
                user = userRepository.save(user);

                // Now create and save OAuth2Provider entry with saved user (which now has ID)
                OAuth2Provider provider = new OAuth2Provider(
                        providerId,
                        providerUserId,
                        user,
                        email,
                        name
                );
                oAuth2ProviderRepository.save(provider);
            }
        }

        // Create OAuth2User object with appropriate permissions
        Collection<SimpleGrantedAuthority> authorities = new ArrayList<>();
        user.getAuthorities().forEach(role ->
                authorities.add(new SimpleGrantedAuthority("ROLE_" + role.getAuthority())));

        Map<String, Object> attributes = new HashMap<>(oAuth2User.getAttributes());
        attributes.put("userId", user.getUserId());

        return new DefaultOAuth2User(
                authorities,
                attributes,
                "email" // Name attribute key in attributes map
        );
    }
}