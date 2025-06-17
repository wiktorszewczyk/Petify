package org.petify.backend.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.petify.backend.dto.LoginRequestDTO;
import org.petify.backend.dto.LoginResponseDTO;
import org.petify.backend.dto.RegistrationDTO;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.Role;
import org.petify.backend.models.VolunteerStatus;
import org.petify.backend.repository.RoleRepository;
import org.petify.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)

class AuthenticationIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    private RegistrationDTO registrationDTO;
    private LoginRequestDTO loginRequestDTO;

    @BeforeEach
    @Transactional
    void setUp() {
        // Create basic roles if they don't exist
        if (roleRepository.findByAuthority("USER").isEmpty()) {
            Role userRole = new Role();
            userRole.setAuthority("USER");
            roleRepository.save(userRole);
        }

        if (roleRepository.findByAuthority("ADMIN").isEmpty()) {
            Role adminRole = new Role();
            adminRole.setAuthority("ADMIN");
            roleRepository.save(adminRole);
        }

        if (roleRepository.findByAuthority("VOLUNTEER").isEmpty()) {
            Role volunteerRole = new Role();
            volunteerRole.setAuthority("VOLUNTEER");
            roleRepository.save(volunteerRole);
        }

        registrationDTO = new RegistrationDTO();
        registrationDTO.setUsername("integrationuser");
        registrationDTO.setEmail("integration@example.com");
        registrationDTO.setPhoneNumber("987654321");
        registrationDTO.setPassword("password123");
        registrationDTO.setFirstName("Integration");
        registrationDTO.setLastName("Test");
        registrationDTO.setBirthDate(LocalDate.of(1990, 1, 1));
        registrationDTO.setGender("MALE");
        registrationDTO.setApplyAsVolunteer(false);

        loginRequestDTO = new LoginRequestDTO();
        loginRequestDTO.setLoginIdentifier("integration@example.com");
        loginRequestDTO.setPassword("password123");
    }

    @Test
    @Transactional
    void completeUserRegistrationAndLoginFlow_ShouldWork() throws Exception {
        // Step 1: Register a new user
        mockMvc.perform(post("/auth/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registrationDTO)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.user.username").value("integrationuser"))
                .andExpect(jsonPath("$.user.email").value("integration@example.com"))
                .andExpect(jsonPath("$.user.xpPoints").value(0))
                .andExpect(jsonPath("$.user.level").value(1))
                .andExpect(jsonPath("$.message").value("User registered successfully"));

        // Verify user was saved to database
        ApplicationUser savedUser = userRepository.findByEmail("integration@example.com").orElse(null);
        assertThat(savedUser).isNotNull();
        assertThat(savedUser.getUsername()).isEqualTo("integrationuser");
        assertThat(savedUser.isActive()).isTrue();
        assertThat(savedUser.getVolunteerStatus()).isEqualTo(VolunteerStatus.NONE);

        // Step 2: Login with the registered user
        MvcResult loginResult = mockMvc.perform(post("/auth/login")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequestDTO)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.username").value("integrationuser"))
                .andExpect(jsonPath("$.jwt").exists())
                .andReturn();

        // Extract JWT token from response
        String responseContent = loginResult.getResponse().getContentAsString();
        LoginResponseDTO loginResponse = objectMapper.readValue(responseContent, LoginResponseDTO.class);
        String jwtToken = loginResponse.getJwt();
        assertThat(jwtToken).isNotNull().isNotEmpty();

        // Step 3: Validate the JWT token
        mockMvc.perform(post("/auth/token/validate")
                        .with(csrf())
                        .header("Authorization", "Bearer " + jwtToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.valid").value(true))
                .andExpect(jsonPath("$.subject").value("integrationuser"));
    }

    @Test
    @Transactional
    void volunteerRegistrationFlow_ShouldWork() throws Exception {
        // Register user as volunteer
        registrationDTO.setApplyAsVolunteer(true);
        registrationDTO.setEmail("volunteer@example.com");
        registrationDTO.setUsername("volunteeruser");

        mockMvc.perform(post("/auth/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registrationDTO)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.user.volunteerStatus").value("PENDING"));

        // Verify volunteer status in database
        ApplicationUser volunteerUser = userRepository.findByEmail("volunteer@example.com").orElse(null);
        assertThat(volunteerUser).isNotNull();
        assertThat(volunteerUser.getVolunteerStatus()).isEqualTo(VolunteerStatus.PENDING);
    }

    @Test
    @Transactional
    void duplicateEmailRegistration_ShouldFail() throws Exception {
        mockMvc.perform(post("/auth/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registrationDTO)))
                .andExpect(status().isCreated());

        RegistrationDTO duplicateEmailDTO = new RegistrationDTO();
        duplicateEmailDTO.setUsername("anotheruser");
        duplicateEmailDTO.setEmail("integration@example.com");
        duplicateEmailDTO.setPhoneNumber("111222333");
        duplicateEmailDTO.setPassword("password456");
        duplicateEmailDTO.setFirstName("Another");
        duplicateEmailDTO.setLastName("User");
        duplicateEmailDTO.setBirthDate(LocalDate.of(1985, 5, 15));
        duplicateEmailDTO.setGender("FEMALE");

        mockMvc.perform(post("/auth/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(duplicateEmailDTO)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Email już jest używany"));
    }

    @Test
    @Transactional
    void duplicatePhoneRegistration_ShouldFail() throws Exception {
        mockMvc.perform(post("/auth/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registrationDTO)))
                .andExpect(status().isCreated());

        RegistrationDTO duplicatePhoneDTO = new RegistrationDTO();
        duplicatePhoneDTO.setUsername("anotheruser");
        duplicatePhoneDTO.setEmail("another@example.com");
        duplicatePhoneDTO.setPhoneNumber("987654321"); // Same phone
        duplicatePhoneDTO.setPassword("password456");
        duplicatePhoneDTO.setFirstName("Another");
        duplicatePhoneDTO.setLastName("User");
        duplicatePhoneDTO.setBirthDate(LocalDate.of(1985, 5, 15));
        duplicatePhoneDTO.setGender("FEMALE");

        mockMvc.perform(post("/auth/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(duplicatePhoneDTO)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Numer telefonu już jest używany"));
    }

    @Test
    @Transactional
    void loginWithInvalidCredentials_ShouldFail() throws Exception {
        mockMvc.perform(post("/auth/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registrationDTO)))
                .andExpect(status().isCreated());

        LoginRequestDTO invalidLoginRequest = new LoginRequestDTO();
        invalidLoginRequest.setLoginIdentifier("integration@example.com");
        invalidLoginRequest.setPassword("wrongpassword");

        mockMvc.perform(post("/auth/login")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidLoginRequest)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Invalid credentials"));
    }

    @Test
    @Transactional
    void loginWithInactiveUser_ShouldFail() throws Exception {
        mockMvc.perform(post("/auth/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registrationDTO)))
                .andExpect(status().isCreated());

        ApplicationUser user = userRepository.findByEmail("integration@example.com").orElseThrow();
        user.setActive(false);
        user.setDeactivationReason("Account suspended for testing");
        userRepository.save(user);

        mockMvc.perform(post("/auth/login")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequestDTO)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Invalid credentials"));
    }

    @Test
    @Transactional
    void validateInvalidToken_ShouldFail() throws Exception {
        mockMvc.perform(post("/auth/token/validate")
                        .with(csrf())
                        .header("Authorization", "Bearer invalid.jwt.token"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @Transactional
    void gamificationInitialization_ShouldWork() throws Exception {
        mockMvc.perform(post("/auth/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registrationDTO)))
                .andExpect(status().isCreated());

        ApplicationUser savedUser = userRepository.findByEmail("integration@example.com").orElse(null);
        assertThat(savedUser).isNotNull();
        assertThat(savedUser.getXpPoints()).isEqualTo(0);
        assertThat(savedUser.getLevel()).isEqualTo(1);
        assertThat(savedUser.getLikesCount()).isEqualTo(0);
        assertThat(savedUser.getSupportCount()).isEqualTo(0);
        assertThat(savedUser.getBadgesCount()).isEqualTo(0);
        assertThat(savedUser.getPreferredSearchDistanceKm()).isEqualTo(20.0);
        assertThat(savedUser.getAutoLocationEnabled()).isFalse();
    }

    @Test
    @Transactional
    void userRoleAssignment_ShouldWork() throws Exception {
        mockMvc.perform(post("/auth/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registrationDTO)))
                .andExpect(status().isCreated());

        ApplicationUser savedUser = userRepository.findByEmail("integration@example.com").orElse(null);
        assertThat(savedUser).isNotNull();
        assertThat(savedUser.getAuthorities()).hasSize(1);
        assertThat(savedUser.getAuthorities().iterator().next().getAuthority()).isEqualTo("USER");
    }

    @Test
    @Transactional
    void usernameGeneration_ShouldWork() throws Exception {
        registrationDTO.setUsername(null);

        mockMvc.perform(post("/auth/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registrationDTO)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.user.username").value("integration@example.com"));

        registrationDTO.setUsername("");
        registrationDTO.setEmail("test2@example.com");
        registrationDTO.setPhoneNumber("123456780");

        mockMvc.perform(post("/auth/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registrationDTO)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.user.username").value("test2@example.com"));

        registrationDTO.setUsername(null);
        registrationDTO.setEmail(null);
        registrationDTO.setPhoneNumber("123456789");

        mockMvc.perform(post("/auth/register")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registrationDTO)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.user.username").value("123456789"));
    }
}
