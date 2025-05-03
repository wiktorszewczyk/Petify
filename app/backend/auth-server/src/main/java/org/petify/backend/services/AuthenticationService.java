package org.petify.backend.services;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.LoginRequestDTO;
import org.petify.backend.models.LoginResponseDTO;
import org.petify.backend.models.RegistrationDTO;
import org.petify.backend.models.Role;
import org.petify.backend.repository.RoleRepository;
import org.petify.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class AuthenticationService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private TokenService tokenService;

    public ApplicationUser registerUser(final RegistrationDTO registrationDTO) {
        // Generate a username based on email or phone
        String username = (registrationDTO.getEmail() != null) ?
                registrationDTO.getEmail() :
                registrationDTO.getPhoneNumber();

        // Check if user with this email or phone already exists
        if (userRepository.findByEmailOrPhoneNumber(
                registrationDTO.getEmail(),
                registrationDTO.getPhoneNumber()).isPresent()) {
            throw new IllegalArgumentException("User with this email or phone number already exists");
        }

        // Encode password
        String encodedPassword = passwordEncoder.encode(registrationDTO.getPassword());

        // Retrieve USER role
        Role userRole = roleRepository.findByAuthority("USER")
                .orElseThrow(() -> new RuntimeException("Default user role not found"));

        Set<Role> authorities = new HashSet<>();
        authorities.add(userRole);

        // Create new user
        ApplicationUser newUser = new ApplicationUser();
        newUser.setUsername(username);
        newUser.setPassword(encodedPassword);
        newUser.setFirstName(registrationDTO.getFirstName());
        newUser.setLastName(registrationDTO.getLastName());
        newUser.setBirthDate(registrationDTO.getBirthDate());
        newUser.setGender(registrationDTO.getGender());
        newUser.setPhoneNumber(registrationDTO.getPhoneNumber());
        newUser.setEmail(registrationDTO.getEmail());
        newUser.setAuthorities(authorities);

        return userRepository.save(newUser);
    }

    public LoginResponseDTO loginUser(final LoginRequestDTO loginRequest) {
        try {
            // Find user by email or phone
            ApplicationUser user = userRepository.findByEmailOrPhoneNumber(
                            loginRequest.getLoginIdentifier(),
                            loginRequest.getLoginIdentifier())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            // Authenticate with username and password
            Authentication auth = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(user.getUsername(), loginRequest.getPassword())
            );

            String token = tokenService.generateJwt(auth);

            return new LoginResponseDTO(user, token);

        } catch (AuthenticationException e) {
            return new LoginResponseDTO(null, "");
        }
    }
}