package org.petify.backend.security.services;

import org.petify.backend.security.models.ApplicationUser;
import org.petify.backend.security.models.OAuth2Provider;
import org.petify.backend.security.models.Role;
import org.petify.backend.security.repository.OAuth2ProviderRepository;
import org.petify.backend.security.repository.RoleRepository;
import org.petify.backend.security.repository.UserRepository;
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

        // Pobieranie danych dostawcy OAuth2
        String providerId = userRequest.getClientRegistration().getRegistrationId();
        String providerUserId = oAuth2User.getAttribute("sub");

        // Pobieranie danych użytkownika z odpowiedzi OAuth
        String email = oAuth2User.getAttribute("email");
        String name = oAuth2User.getAttribute("name");

        // Sprawdzanie, czy już wcześniej widzieliśmy tego użytkownika
        Optional<OAuth2Provider> existingProvider =
                oAuth2ProviderRepository.findByProviderIdAndProviderUserId(providerId, providerUserId);

        ApplicationUser user;

        if (existingProvider.isPresent()) {
            // Już wcześniej logował się ten użytkownik - pobierz jego dane
            user = existingProvider.get().getUser();

            // Aktualizacja danych użytkownika jeśli potrzeba
            existingProvider.get().setEmail(email);
            existingProvider.get().setName(name);
            oAuth2ProviderRepository.save(existingProvider.get());
        } else {
            // To nowy użytkownik OAuth2

            // Generowanie unikalnej nazwy użytkownika na podstawie emaila lub imienia
            String username = (email != null) ? email : name + "_" + UUID.randomUUID().toString().substring(0, 8);

            // Sprawdzenie czy użytkownik o tym emailu już istnieje
            Optional<ApplicationUser> existingUser = userRepository.findByUsername(username);

            if (existingUser.isPresent()) {
                user = existingUser.get();
            } else {
                // Tworzenie nowego użytkownika
                Role userRole = roleRepository.findByAuthority("USER")
                        .orElseThrow(() -> new RuntimeException("Nie znaleziono roli 'USER'"));

                Set<Role> authorities = new HashSet<>();
                authorities.add(userRole);

                user = new ApplicationUser();
                user.setUsername(username);
                // Dla użytkowników OAuth2 ustawiamy bezpieczne losowe hasło, którego nie będą używać
                user.setPassword(passwordEncoder.encode(UUID.randomUUID().toString()));
                user.setAuthorities(authorities);

                // Najpierw zapisujemy użytkownika, aby otrzymał ID
                user = userRepository.save(user);

                // Teraz tworzymy i zapisujemy wpis OAuth2Provider z zapisanym użytkownikiem (który ma już ID)
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

        // Tworzenie obiektu OAuth2User z odpowiednimi uprawnieniami
        Collection<SimpleGrantedAuthority> authorities = new ArrayList<>();
        user.getAuthorities().forEach(role ->
                authorities.add(new SimpleGrantedAuthority("ROLE_" + role.getAuthority())));

        Map<String, Object> attributes = new HashMap<>(oAuth2User.getAttributes());
        attributes.put("userId", user.getUserId());

        return new DefaultOAuth2User(
                authorities,
                attributes,
                "email" // Klucz atrybutu nazwy w mapie atrybutów
        );
    }
}