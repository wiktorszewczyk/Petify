package org.petify.backend.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.backend.dto.LoginRequestDTO;
import org.petify.backend.dto.LoginResponseDTO;
import org.petify.backend.dto.RegistrationDTO;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.Role;
import org.petify.backend.models.VolunteerStatus;
import org.petify.backend.repository.RoleRepository;
import org.petify.backend.repository.UserRepository;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthenticationServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private RoleRepository roleRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private AuthenticationManager authenticationManager;

    @Mock
    private TokenService tokenService;

    @Mock
    private AchievementService achievementService;

    @InjectMocks
    private AuthenticationService authenticationService;

    private RegistrationDTO registrationDTO;
    private ApplicationUser testUser;
    private Role userRole;
    private LoginRequestDTO loginRequest;

    @BeforeEach
    void setUp() {
        registrationDTO = new RegistrationDTO();
        registrationDTO.setUsername("testuser");
        registrationDTO.setEmail("test@example.com");
        registrationDTO.setPhoneNumber("123456789");
        registrationDTO.setPassword("password123");
        registrationDTO.setFirstName("John");
        registrationDTO.setLastName("Doe");
        registrationDTO.setBirthDate(LocalDate.of(1990, 1, 1));
        registrationDTO.setGender("MALE");
        registrationDTO.setApplyAsVolunteer(false);

        userRole = new Role();
        userRole.setAuthority("USER");

        testUser = new ApplicationUser();
        testUser.setUsername("testuser");
        testUser.setEmail("test@example.com");
        testUser.setPhoneNumber("123456789");
        testUser.setPassword("encodedPassword");
        testUser.setFirstName("John");
        testUser.setLastName("Doe");
        testUser.setActive(true);
        testUser.setVolunteerStatus(VolunteerStatus.NONE);
        testUser.setXpPoints(0);
        testUser.setLevel(1);
        testUser.setCreatedAt(LocalDateTime.now());

        loginRequest = new LoginRequestDTO();
        loginRequest.setLoginIdentifier("test@example.com");
        loginRequest.setPassword("password123");
    }

    @Test
    void registerUser_WhenValidRegistration_ShouldCreateUserSuccessfully() {
        when(userRepository.findByEmailOrPhoneNumber(anyString(), anyString())).thenReturn(Optional.empty());
        when(passwordEncoder.encode(anyString())).thenReturn("encodedPassword");
        when(roleRepository.findByAuthority("USER")).thenReturn(Optional.of(userRole));
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);

        ApplicationUser result = authenticationService.registerUser(registrationDTO);

        assertThat(result).isNotNull();
        assertThat(result.getUsername()).isEqualTo("testuser");
        assertThat(result.getEmail()).isEqualTo("test@example.com");
        assertThat(result.getXpPoints()).isEqualTo(0);
        assertThat(result.getLevel()).isEqualTo(1);
        assertThat(result.getVolunteerStatus()).isEqualTo(VolunteerStatus.NONE);

        verify(userRepository).findByEmailOrPhoneNumber("test@example.com", "123456789");
        verify(passwordEncoder).encode("password123");
        verify(userRepository).save(any(ApplicationUser.class));
        verify(achievementService).initializeUserAchievements(any(ApplicationUser.class));
    }

    @Test
    void registerUser_WhenUserExists_ShouldThrowException() {
        when(userRepository.findByEmailOrPhoneNumber(anyString(), anyString())).thenReturn(Optional.of(testUser));

        assertThatThrownBy(() -> authenticationService.registerUser(registrationDTO))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("User with this email or phone number already exists");

        verify(userRepository, never()).save(any(ApplicationUser.class));
        verify(achievementService, never()).initializeUserAchievements(any(ApplicationUser.class));
    }

    @Test
    void registerUser_WhenApplyAsVolunteer_ShouldSetVolunteerStatusToPending() {
        registrationDTO.setApplyAsVolunteer(true);
        when(userRepository.findByEmailOrPhoneNumber(anyString(), anyString())).thenReturn(Optional.empty());
        when(passwordEncoder.encode(anyString())).thenReturn("encodedPassword");
        when(roleRepository.findByAuthority("USER")).thenReturn(Optional.of(userRole));

        ApplicationUser volunteerUser = new ApplicationUser();
        volunteerUser.setVolunteerStatus(VolunteerStatus.PENDING);
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(volunteerUser);

        ApplicationUser result = authenticationService.registerUser(registrationDTO);

        assertThat(result.getVolunteerStatus()).isEqualTo(VolunteerStatus.PENDING);
    }

    @Test
    void registerUser_WhenUsernameIsEmpty_ShouldUseEmailAsUsername() {
        registrationDTO.setUsername("");
        when(userRepository.findByEmailOrPhoneNumber(anyString(), anyString())).thenReturn(Optional.empty());
        when(passwordEncoder.encode(anyString())).thenReturn("encodedPassword");
        when(roleRepository.findByAuthority("USER")).thenReturn(Optional.of(userRole));
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);

        authenticationService.registerUser(registrationDTO);

        verify(userRepository).save(argThat(user -> user.getUsername().equals("test@example.com")));
    }

    @Test
    void registerUser_WhenDefaultRoleNotFound_ShouldThrowException() {
        when(userRepository.findByEmailOrPhoneNumber(anyString(), anyString())).thenReturn(Optional.empty());
        when(passwordEncoder.encode(anyString())).thenReturn("encodedPassword");
        when(roleRepository.findByAuthority("USER")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authenticationService.registerUser(registrationDTO))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Default user role not found");
    }

    @Test
    void loginUser_WhenValidCredentials_ShouldReturnLoginResponse() {
        Authentication mockAuth = mock(Authentication.class);
        when(userRepository.findByEmailOrPhoneNumber(anyString(), anyString())).thenReturn(Optional.of(testUser));
        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class))).thenReturn(mockAuth);
        when(tokenService.generateJwt(mockAuth)).thenReturn("jwt-token");

        LoginResponseDTO result = authenticationService.loginUser(loginRequest);

        assertThat(result).isNotNull();
        assertThat(result.getUser()).isEqualTo(testUser);
        assertThat(result.getJwt()).isEqualTo("jwt-token");
        assertThat(result.getErrorMessage()).isNull();
    }

    @Test
    void loginUser_WhenUserIsInactive_ShouldReturnDisabledError() {
        testUser.setActive(false);
        testUser.setDeactivationReason("Account suspended");
        when(userRepository.findByEmailOrPhoneNumber(anyString(), anyString())).thenReturn(Optional.of(testUser));

        LoginResponseDTO result = authenticationService.loginUser(loginRequest);

        assertThat(result.getUser()).isNull();
        assertThat(result.getJwt()).isEmpty();
        assertThat(result.getErrorMessage()).isEqualTo("Account suspended");
    }

    @Test
    void loginUser_WhenInvalidCredentials_ShouldReturnErrorResponse() {
        when(userRepository.findByEmailOrPhoneNumber(anyString(), anyString())).thenReturn(Optional.of(testUser));
        when(authenticationManager.authenticate(any(UsernamePasswordAuthenticationToken.class)))
                .thenThrow(new AuthenticationException("Bad credentials") {});

        LoginResponseDTO result = authenticationService.loginUser(loginRequest);

        assertThat(result.getUser()).isNull();
        assertThat(result.getJwt()).isEmpty();
        assertThat(result.getErrorMessage()).isEqualTo("Invalid credentials");
    }

    @Test
    void updateUserProfile_WhenValidUpdate_ShouldUpdateUser() {
        ApplicationUser updatedUser = new ApplicationUser();
        updatedUser.setFirstName("Jane");
        updatedUser.setLastName("Smith");
        updatedUser.setEmail("newemail@example.com");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(userRepository.findByEmail("newemail@example.com")).thenReturn(Optional.empty());
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);

        ApplicationUser result = authenticationService.updateUserProfile("testuser", updatedUser);

        assertThat(result).isNotNull();
        verify(userRepository).save(testUser);
    }

    @Test
    void updateUserProfile_WhenEmailAlreadyExists_ShouldThrowException() {
        ApplicationUser updatedUser = new ApplicationUser();
        updatedUser.setEmail("existing@example.com");

        ApplicationUser existingUser = new ApplicationUser();
        existingUser.setEmail("existing@example.com");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(userRepository.findByEmail("existing@example.com")).thenReturn(Optional.of(existingUser));

        assertThatThrownBy(() -> authenticationService.updateUserProfile("testuser", updatedUser))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Email is already in use");
    }

    @Test
    void updateUserProfile_WhenPhoneNumberAlreadyExists_ShouldThrowException() {
        ApplicationUser updatedUser = new ApplicationUser();
        updatedUser.setPhoneNumber("987654321");

        ApplicationUser existingUser = new ApplicationUser();
        existingUser.setPhoneNumber("987654321");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(userRepository.findByPhoneNumber("987654321")).thenReturn(Optional.of(existingUser));

        assertThatThrownBy(() -> authenticationService.updateUserProfile("testuser", updatedUser))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Phone number is already in use");
    }

    @Test
    void updateUserProfile_WhenUserNotFound_ShouldThrowException() {
        ApplicationUser updatedUser = new ApplicationUser();
        when(userRepository.findByUsername("nonexistent")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authenticationService.updateUserProfile("nonexistent", updatedUser))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("User not found");
    }

    @Test
    void deleteUserAccount_WhenUserExists_ShouldDeleteUser() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));

        authenticationService.deleteUserAccount("testuser");

        verify(userRepository).delete(testUser);
    }

    @Test
    void deleteUserAccount_WhenUserNotFound_ShouldThrowException() {
        when(userRepository.findByUsername("nonexistent")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authenticationService.deleteUserAccount("nonexistent"))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("User not found");
    }

    @Test
    void updateVolunteerStatus_WhenUserExists_ShouldUpdateStatus() {
        // Ustawmy ID na testUser
        testUser.setUserId(1);
        when(userRepository.findById(1)).thenReturn(Optional.of(testUser));
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);

        ApplicationUser result = authenticationService.updateVolunteerStatus(1, VolunteerStatus.ACTIVE);

        assertThat(result).isNotNull();
        verify(userRepository).save(testUser);
        assertThat(testUser.getVolunteerStatus()).isEqualTo(VolunteerStatus.ACTIVE);
    }

    @Test
    void assignRolesToUser_WhenValidRoles_ShouldAssignRoles() {
        Role adminRole = new Role();
        adminRole.setAuthority("ADMIN");

        Set<String> roleNames = Set.of("USER", "ADMIN");

        testUser.setUserId(1);
        when(userRepository.findById(1)).thenReturn(Optional.of(testUser));
        when(roleRepository.findByAuthority("USER")).thenReturn(Optional.of(userRole));
        when(roleRepository.findByAuthority("ADMIN")).thenReturn(Optional.of(adminRole));
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);

        ApplicationUser result = authenticationService.assignRolesToUser(1, roleNames);

        assertThat(result).isNotNull();
        verify(userRepository).save(testUser);
    }

    @Test
    void assignRolesToUser_WhenRoleNotFound_ShouldThrowException() {
        Set<String> roleNames = Set.of("INVALID_ROLE");

        // Ustawmy ID na testUser
        testUser.setUserId(1);
        when(userRepository.findById(1)).thenReturn(Optional.of(testUser));
        when(roleRepository.findByAuthority("INVALID_ROLE")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> authenticationService.assignRolesToUser(1, roleNames))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Role not found: INVALID_ROLE");
    }

    @Test
    void deactivateUserAccount_WhenUserExists_ShouldDeactivateUser() {
        // Ustawmy ID na testUser
        testUser.setUserId(1);
        when(userRepository.findById(1)).thenReturn(Optional.of(testUser));
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);

        ApplicationUser result = authenticationService.deactivateUserAccount(1, "Policy violation");

        assertThat(result).isNotNull();
        assertThat(testUser.isActive()).isFalse();
        assertThat(testUser.getDeactivationReason()).isEqualTo("Policy violation");
        verify(userRepository).save(testUser);
    }

    @Test
    void reactivateUserAccount_WhenUserExists_ShouldReactivateUser() {
        testUser.setActive(false);
        testUser.setDeactivationReason("Test reason");

        // Ustawmy ID na testUser
        testUser.setUserId(1);
        when(userRepository.findById(1)).thenReturn(Optional.of(testUser));
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);

        ApplicationUser result = authenticationService.reactivateUserAccount(1);

        assertThat(result).isNotNull();
        assertThat(testUser.isActive()).isTrue();
        assertThat(testUser.getDeactivationReason()).isNull();
        verify(userRepository).save(testUser);
    }

    @Test
    void selfDeactivateAccount_WhenUserExists_ShouldDeactivateAccount() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);

        ApplicationUser result = authenticationService.selfDeactivateAccount("testuser", "Personal reasons");

        assertThat(result).isNotNull();
        assertThat(testUser.isActive()).isFalse();
        assertThat(testUser.getDeactivationReason()).isEqualTo("Personal reasons");
        verify(userRepository).save(testUser);
    }
}
