package org.petify.backend.services;

import org.petify.backend.dto.LoginRequestDTO;
import org.petify.backend.dto.LoginResponseDTO;
import org.petify.backend.dto.RegistrationDTO;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.Role;
import org.petify.backend.models.VolunteerStatus;
import org.petify.backend.repository.RoleRepository;
import org.petify.backend.repository.UserRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

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

    @Autowired
    private AchievementService achievementService;

    public ApplicationUser registerUser(final RegistrationDTO registrationDTO) {
        final String username = (registrationDTO.getUsername() != null && !registrationDTO.getUsername().isEmpty())
                ? registrationDTO.getUsername()
                : (registrationDTO.getEmail() != null)
                ? registrationDTO.getEmail()
                : registrationDTO.getPhoneNumber();

        if (userRepository.findByEmailOrPhoneNumber(
                registrationDTO.getEmail(),
                registrationDTO.getPhoneNumber()).isPresent()) {
            throw new IllegalArgumentException("User with this email or phone number already exists");
        }

        final String encodedPassword = passwordEncoder.encode(registrationDTO.getPassword());

        Role userRole = roleRepository.findByAuthority("USER")
                .orElseThrow(() -> new RuntimeException("Default user role not found"));

        Set<Role> authorities = new HashSet<>();
        authorities.add(userRole);

        // If user wants to create a shelter, assign SHELTER role
        if (registrationDTO.isCreateShelter()) {
            Role shelterRole = roleRepository.findByAuthority("SHELTER")
                    .orElseThrow(() -> new RuntimeException("SHELTER role not found"));
            authorities.add(shelterRole);
        }

        ApplicationUser newUser = new ApplicationUser();
        newUser.setUsername(username);
        newUser.setPassword(encodedPassword);
        newUser.setFirstName(registrationDTO.getFirstName());
        newUser.setLastName(registrationDTO.getLastName());
        newUser.setBirthDate(registrationDTO.getBirthDate());
        newUser.setGender(registrationDTO.getGender());
        newUser.setPhoneNumber(registrationDTO.getPhoneNumber());
        newUser.setEmail(registrationDTO.getEmail());
        newUser.setActive(true);
        newUser.setCreatedAt(LocalDateTime.now());

        newUser.setXpPoints(0);
        newUser.setLevel(1);
        newUser.setLikesCount(0);
        newUser.setSupportCount(0);
        newUser.setBadgesCount(0);

        newUser.setPreferredSearchDistanceKm(20.0);
        newUser.setAutoLocationEnabled(false);

        if (registrationDTO.isApplyAsVolunteer() && !registrationDTO.isCreateShelter()) { // Volunteer only if not creating shelter
            newUser.setVolunteerStatus(VolunteerStatus.PENDING);
        } else {
            newUser.setVolunteerStatus(VolunteerStatus.NONE);
        }

        newUser.setAuthorities(authorities);

        ApplicationUser savedUser = userRepository.save(newUser);

        achievementService.initializeUserAchievements(savedUser);

        return savedUser;
    }

    public LoginResponseDTO loginUser(final LoginRequestDTO loginRequest) {
        try {
            ApplicationUser user = userRepository.findByEmailOrPhoneNumber(
                            loginRequest.getLoginIdentifier(),
                            loginRequest.getLoginIdentifier())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            if (!user.isActive()) {
                String deactivationReason = user.getDeactivationReason() != null
                        ? user.getDeactivationReason() : "Account has been deactivated";
                throw new DisabledException(deactivationReason);
            }

            Authentication auth = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(user.getUsername(), loginRequest.getPassword())
            );

            String token = tokenService.generateJwt(auth);

            return new LoginResponseDTO(user, token);

        } catch (DisabledException e) {
            return new LoginResponseDTO(null, "", e.getMessage());
        } catch (AuthenticationException e) {
            return new LoginResponseDTO(null, "", "Invalid credentials");
        }
    }

    public ApplicationUser updateUserProfile(String username, ApplicationUser updatedUser) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (updatedUser.getEmail() != null && !updatedUser.getEmail().equals(user.getEmail())) {
            if (userRepository.findByEmail(updatedUser.getEmail()).isPresent()) {
                throw new IllegalArgumentException("Email is already in use");
            }
            user.setEmail(updatedUser.getEmail());
        }

        if (updatedUser.getPhoneNumber() != null && !updatedUser.getPhoneNumber().equals(user.getPhoneNumber())) {
            if (userRepository.findByPhoneNumber(updatedUser.getPhoneNumber()).isPresent()) {
                throw new IllegalArgumentException("Phone number is already in use");
            }
            user.setPhoneNumber(updatedUser.getPhoneNumber());
        }

        if (updatedUser.getFirstName() != null) {
            user.setFirstName(updatedUser.getFirstName());
        }

        if (updatedUser.getLastName() != null) {
            user.setLastName(updatedUser.getLastName());
        }

        if (updatedUser.getBirthDate() != null) {
            user.setBirthDate(updatedUser.getBirthDate());
        }

        if (updatedUser.getGender() != null) {
            user.setGender(updatedUser.getGender());
        }

        if (updatedUser.getPreferredSearchDistanceKm() != null) {
            user.setPreferredSearchDistanceKm(updatedUser.getPreferredSearchDistanceKm());
        }

        if (updatedUser.getAutoLocationEnabled() != null) {
            user.setAutoLocationEnabled(updatedUser.getAutoLocationEnabled());
        }

        return userRepository.save(user);
    }

    public void deleteUserAccount(String username) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        userRepository.delete(user);
    }

    public ApplicationUser updateVolunteerStatus(Integer userId, VolunteerStatus status) {
        ApplicationUser user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setVolunteerStatus(status);
        return userRepository.save(user);
    }

    public ApplicationUser assignRolesToUser(Integer userId, Set<String> roleNames) {
        ApplicationUser user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Set<Role> roles = new HashSet<>();
        for (String roleName : roleNames) {
            Role role = roleRepository.findByAuthority(roleName)
                    .orElseThrow(() -> new RuntimeException("Role not found: " + roleName));
            roles.add(role);
        }

        user.setAuthorities(roles);
        return userRepository.save(user);
    }

    @Transactional
    public ApplicationUser deactivateUserAccount(Integer userId, String reason) {
        ApplicationUser user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setActive(false);
        user.setDeactivationReason(reason);

        return userRepository.save(user);
    }

    @Transactional
    public ApplicationUser reactivateUserAccount(Integer userId) {
        ApplicationUser user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setActive(true);
        user.setDeactivationReason(null);

        return userRepository.save(user);
    }

    @Transactional
    public ApplicationUser selfDeactivateAccount(String username, String reason) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setActive(false);
        user.setDeactivationReason(reason);

        return userRepository.save(user);
    }
}
