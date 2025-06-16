//package org.petify.backend.integration;
//
//import com.fasterxml.jackson.databind.ObjectMapper;
//import org.junit.jupiter.api.BeforeEach;
//import org.junit.jupiter.api.Test;
//import org.junit.jupiter.api.extension.ExtendWith;
//import org.mockito.junit.jupiter.MockitoExtension;
//import org.petify.backend.controllers.AuthenticationController;
//import org.petify.backend.dto.LoginRequestDTO;
//import org.petify.backend.dto.LoginResponseDTO;
//import org.petify.backend.dto.RegistrationDTO;
//import org.petify.backend.models.ApplicationUser;
//import org.petify.backend.repository.UserRepository;
//import org.petify.backend.services.AuthenticationService;
//import org.petify.backend.services.OAuth2TokenService;
//import org.petify.backend.services.ProfileAchievementService;
//import org.petify.backend.services.TokenService;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
//import org.springframework.dao.DataIntegrityViolationException;
//import org.springframework.http.MediaType;
//import org.springframework.mock.web.MockMultipartFile;
//import org.springframework.security.oauth2.jwt.Jwt;
//import org.springframework.security.oauth2.jwt.JwtException;
//import org.springframework.security.test.context.support.WithMockUser;
//import org.springframework.test.context.bean.override.mockito.MockitoBean;
//import org.springframework.test.web.servlet.MockMvc;
//
//import java.time.Instant;
//import java.time.LocalDate;
//import java.util.Optional;
//
//import static org.hamcrest.Matchers.containsString;
//import static org.mockito.ArgumentMatchers.*;
//import static org.mockito.Mockito.*;
//import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
//import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
//import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
//
//@ExtendWith(MockitoExtension.class)
//@WebMvcTest(AuthenticationController.class)
//class AuthenticationControllerTest {
//
//    @Autowired
//    private MockMvc mockMvc;
//
//    @Autowired
//    private ObjectMapper objectMapper;
//
//    @MockitoBean
//    private AuthenticationService authenticationService;
//
//    @MockitoBean
//    private TokenService tokenService;
//
//    @MockitoBean
//    private OAuth2TokenService oauth2TokenService;
//
//    @MockitoBean
//    private UserRepository userRepository;
//
//    @MockitoBean
//    private ProfileAchievementService profileAchievementService;
//
//    private RegistrationDTO registrationDTO;
//    private LoginRequestDTO loginRequestDTO;
//    private ApplicationUser testUser;
//    private LoginResponseDTO loginResponseDTO;
//
//    @BeforeEach
//    void setUp() {
//        registrationDTO = new RegistrationDTO();
//        registrationDTO.setUsername("testuser");
//        registrationDTO.setEmail("test@example.com");
//        registrationDTO.setPhoneNumber("123456789");
//        registrationDTO.setPassword("password123");
//        registrationDTO.setFirstName("John");
//        registrationDTO.setLastName("Doe");
//        registrationDTO.setBirthDate(LocalDate.of(1990, 1, 1));
//        registrationDTO.setGender("MALE");
//        registrationDTO.setApplyAsVolunteer(false);
//
//        loginRequestDTO = new LoginRequestDTO();
//        loginRequestDTO.setLoginIdentifier("test@example.com");
//        loginRequestDTO.setPassword("password123");
//
//        testUser = new ApplicationUser();
//        testUser.setUserId(1);
//        testUser.setUsername("testuser");
//        testUser.setEmail("test@example.com");
//        testUser.setPhoneNumber("123456789");
//        testUser.setFirstName("John");
//        testUser.setLastName("Doe");
//        testUser.setActive(true);
//
//        loginResponseDTO = new LoginResponseDTO(testUser, "jwt-token");
//    }
//
//    @Test
//    void registerUser_WhenValidRegistration_ShouldReturnCreated() throws Exception {
//        when(userRepository.findByEmail(anyString())).thenReturn(Optional.empty());
//        when(userRepository.findByPhoneNumber(anyString())).thenReturn(Optional.empty());
//        when(authenticationService.registerUser(any(RegistrationDTO.class))).thenReturn(testUser);
//
//        mockMvc.perform(post("/auth/register")
//                        .with(csrf())
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(objectMapper.writeValueAsString(registrationDTO)))
//                .andExpect(status().isCreated())
//                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
//                .andExpect(jsonPath("$.user.username").value("testuser"))
//                .andExpect(jsonPath("$.message").value("User registered successfully"));
//
//        verify(authenticationService).registerUser(any(RegistrationDTO.class));
//    }
//
//    @Test
//    void registerUser_WhenEmailAlreadyExists_ShouldReturnBadRequest() throws Exception {
//        when(userRepository.findByEmail("test@example.com")).thenReturn(Optional.of(testUser));
//
//        mockMvc.perform(post("/auth/register")
//                        .with(csrf())
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(objectMapper.writeValueAsString(registrationDTO)))
//                .andExpect(status().isBadRequest())
//                .andExpect(jsonPath("$.error").value("Email już jest używany"));
//
//        verify(authenticationService, never()).registerUser(any(RegistrationDTO.class));
//    }
//
//    @Test
//    void registerUser_WhenPhoneNumberAlreadyExists_ShouldReturnBadRequest() throws Exception {
//        when(userRepository.findByEmail(anyString())).thenReturn(Optional.empty());
//        when(userRepository.findByPhoneNumber("123456789")).thenReturn(Optional.of(testUser));
//
//        mockMvc.perform(post("/auth/register")
//                        .with(csrf())
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(objectMapper.writeValueAsString(registrationDTO)))
//                .andExpect(status().isBadRequest())
//                .andExpect(jsonPath("$.error").value("Numer telefonu już jest używany"));
//
//        verify(authenticationService, never()).registerUser(any(RegistrationDTO.class));
//    }
//
//    @Test
//    void registerUser_WhenDataIntegrityViolation_ShouldReturnBadRequest() throws Exception {
//        when(userRepository.findByEmail(anyString())).thenReturn(Optional.empty());
//        when(userRepository.findByPhoneNumber(anyString())).thenReturn(Optional.empty());
//        when(authenticationService.registerUser(any(RegistrationDTO.class)))
//                .thenThrow(new DataIntegrityViolationException("Database constraint violation"));
//
//        mockMvc.perform(post("/auth/register")
//                        .with(csrf())
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(objectMapper.writeValueAsString(registrationDTO)))
//                .andExpect(status().isBadRequest())
//                .andExpect(jsonPath("$.error").value(containsString("Naruszenie ograniczeń bazy danych")));
//    }
//
//    @Test
//    void registerUser_WhenIllegalArgument_ShouldReturnBadRequest() throws Exception {
//        when(userRepository.findByEmail(anyString())).thenReturn(Optional.empty());
//        when(userRepository.findByPhoneNumber(anyString())).thenReturn(Optional.empty());
//        when(authenticationService.registerUser(any(RegistrationDTO.class)))
//                .thenThrow(new IllegalArgumentException("Invalid registration data"));
//
//        mockMvc.perform(post("/auth/register")
//                        .with(csrf())
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(objectMapper.writeValueAsString(registrationDTO)))
//                .andExpect(status().isBadRequest())
//                .andExpect(jsonPath("$.error").value("Invalid registration data"));
//    }
//
//    @Test
//    void loginUser_WhenValidCredentials_ShouldReturnOk() throws Exception {
//        when(authenticationService.loginUser(any(LoginRequestDTO.class))).thenReturn(loginResponseDTO);
//
//        mockMvc.perform(post("/auth/login")
//                        .with(csrf())
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(objectMapper.writeValueAsString(loginRequestDTO)))
//                .andExpect(status().isOk())
//                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
//                .andExpect(jsonPath("$.user.username").value("testuser"))
//                .andExpect(jsonPath("$.jwt").value("jwt-token"));
//
//        verify(authenticationService).loginUser(any(LoginRequestDTO.class));
//    }
//
//    @Test
//    void loginUser_WhenInvalidCredentials_ShouldReturnUnauthorized() throws Exception {
//        LoginResponseDTO errorResponse = new LoginResponseDTO(null, "", "Invalid credentials");
//        when(authenticationService.loginUser(any(LoginRequestDTO.class))).thenReturn(errorResponse);
//
//        mockMvc.perform(post("/auth/login")
//                        .with(csrf())
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(objectMapper.writeValueAsString(loginRequestDTO)))
//                .andExpect(status().isUnauthorized())
//                .andExpect(jsonPath("$.error").value("Invalid credentials"));
//    }
//
//    @Test
//    void validateToken_WhenValidToken_ShouldReturnValid() throws Exception {
//        Jwt mockJwt = mock(Jwt.class);
//        when(mockJwt.getSubject()).thenReturn("testuser");
//        when(mockJwt.getExpiresAt()).thenReturn(Instant.now().plusSeconds(3600));
//        when(tokenService.validateJwt("valid-token")).thenReturn(mockJwt);
//
//        mockMvc.perform(post("/auth/token/validate")
//                        .with(csrf())
//                        .header("Authorization", "Bearer valid-token"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.valid").value(true))
//                .andExpect(jsonPath("$.subject").value("testuser"));
//
//        verify(tokenService).validateJwt("valid-token");
//    }
//
//    @Test
//    void validateToken_WhenInvalidToken_ShouldReturnUnauthorized() throws Exception {
//        when(tokenService.validateJwt("invalid-token")).thenThrow(new JwtException("Invalid token"));
//
//        mockMvc.perform(post("/auth/token/validate")
//                        .with(csrf())
//                        .header("Authorization", "Bearer invalid-token"))
//                .andExpect(status().isUnauthorized())
//                .andExpect(jsonPath("$.valid").value(false))
//                .andExpect(jsonPath("$.error").value("Invalid token"));
//    }
//
//    @Test
//    @WithMockUser(username = "testuser")
//    void getUserData_WhenAuthenticated_ShouldReturnUserData() throws Exception {
//        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
//
//        mockMvc.perform(get("/user"))
//                .andExpect(status().isOk())
//                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
//                .andExpect(jsonPath("$.username").value("testuser"))
//                .andExpect(jsonPath("$.email").value("test@example.com"));
//
//        verify(userRepository).findByUsername("testuser");
//    }
//
//    @Test
//    void getUserData_WhenNotAuthenticated_ShouldReturnUnauthorized() throws Exception {
//        mockMvc.perform(get("/user"))
//                .andExpect(status().isUnauthorized());
//
//        verify(userRepository, never()).findByUsername(any());
//    }
//
//    @Test
//    @WithMockUser(username = "testuser")
//    void updateUserData_WhenAuthenticated_ShouldReturnUpdatedUser() throws Exception {
//        ApplicationUser updatedUser = new ApplicationUser();
//        updatedUser.setFirstName("Jane");
//        updatedUser.setLastName("Smith");
//
//        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
//        when(authenticationService.updateUserProfile(anyString(), any(ApplicationUser.class))).thenReturn(testUser);
//
//        mockMvc.perform(put("/user")
//                        .with(csrf())
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(objectMapper.writeValueAsString(updatedUser)))
//                .andExpect(status().isOk())
//                .andExpect(content().contentType(MediaType.APPLICATION_JSON));
//
//        verify(authenticationService).updateUserProfile(eq("testuser"), any(ApplicationUser.class));
//        verify(profileAchievementService).onProfileUpdated("testuser");
//    }
//
//    @Test
//    @WithMockUser(username = "testuser")
//    void updateUserData_WhenIllegalArgument_ShouldReturnBadRequest() throws Exception {
//        ApplicationUser updatedUser = new ApplicationUser();
//        when(authenticationService.updateUserProfile(anyString(), any(ApplicationUser.class)))
//                .thenThrow(new IllegalArgumentException("Invalid data"));
//
//        mockMvc.perform(put("/user")
//                        .with(csrf())
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(objectMapper.writeValueAsString(updatedUser)))
//                .andExpect(status().isBadRequest());
//    }
//
//    @Test
//    @WithMockUser(username = "testuser")
//    void deleteUser_WhenAuthenticated_ShouldReturnOk() throws Exception {
//        doNothing().when(authenticationService).deleteUserAccount("testuser");
//
//        mockMvc.perform(delete("/user")
//                        .with(csrf()))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.message").value("User account successfully deleted"));
//
//        verify(authenticationService).deleteUserAccount("testuser");
//    }
//
//    @Test
//    void deleteUser_WhenNotAuthenticated_ShouldReturnUnauthorized() throws Exception {
//        mockMvc.perform(delete("/user")
//                        .with(csrf()))
//                .andExpect(status().isUnauthorized())
//                .andExpect(jsonPath("$.error").value("User not authenticated"));
//
//        verify(authenticationService, never()).deleteUserAccount(any());
//    }
//
//    @Test
//    @WithMockUser(username = "testuser")
//    void selfDeactivateAccount_WhenAuthenticated_ShouldReturnOk() throws Exception {
//        when(authenticationService.selfDeactivateAccount(anyString(), anyString())).thenReturn(testUser);
//
//        mockMvc.perform(post("/user/deactivate")
//                        .with(csrf())
//                        .param("reason", "Personal reasons"))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.message").value("Your account has been deactivated successfully"));
//
//        verify(authenticationService).selfDeactivateAccount("testuser", "Personal reasons");
//    }
//
//    @Test
//    @WithMockUser(username = "testuser")
//    void uploadProfileImage_WhenValidImage_ShouldReturnOk() throws Exception {
//        MockMultipartFile image = new MockMultipartFile(
//                "image", "test.jpg", "image/jpeg", "test image content".getBytes());
//
//        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
//        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);
//
//        mockMvc.perform(multipart("/user/profile-image")
//                        .file(image)
//                        .with(csrf()))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.message").value("Profile image uploaded successfully"))
//                .andExpect(jsonPath("$.hasImage").value(true));
//
//        verify(userRepository).save(any(ApplicationUser.class));
//        verify(profileAchievementService).onProfileImageAdded("testuser");
//    }
//
//    @Test
//    @WithMockUser(username = "testuser")
//    void uploadProfileImage_WhenImageTooLarge_ShouldReturnBadRequest() throws Exception {
//        byte[] largeImageContent = new byte[6 * 1024 * 1024]; // 6MB
//        MockMultipartFile image = new MockMultipartFile(
//                "image", "test.jpg", "image/jpeg", largeImageContent);
//
//        mockMvc.perform(multipart("/user/profile-image")
//                        .file(image)
//                        .with(csrf()))
//                .andExpect(status().isBadRequest())
//                .andExpect(jsonPath("$.error").value("Image file too large. Maximum size is 5MB"));
//
//        verify(userRepository, never()).save(any(ApplicationUser.class));
//        verify(profileAchievementService, never()).onProfileImageAdded(any());
//    }
//
//    @Test
//    @WithMockUser(username = "testuser")
//    void uploadProfileImage_WhenUnsupportedFormat_ShouldReturnBadRequest() throws Exception {
//        MockMultipartFile image = new MockMultipartFile(
//                "image", "test.txt", "text/plain", "not an image".getBytes());
//
//        mockMvc.perform(multipart("/user/profile-image")
//                        .file(image)
//                        .with(csrf()))
//                .andExpect(status().isBadRequest())
//                .andExpect(jsonPath("$.error").value("Unsupported image format. Allowed: JPEG, PNG, GIF, WebP"));
//
//        verify(userRepository, never()).save(any(ApplicationUser.class));
//        verify(profileAchievementService, never()).onProfileImageAdded(any());
//    }
//
//    @Test
//    @WithMockUser(username = "testuser")
//    void getProfileImage_WhenImageExists_ShouldReturnImage() throws Exception {
//        byte[] imageData = "test image data".getBytes();
//        testUser.setProfileImage(imageData);
//        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
//
//        mockMvc.perform(get("/user/profile-image"))
//                .andExpect(status().isOk())
//                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
//                .andExpect(jsonPath("$.hasImage").value("true"))
//                .andExpect(jsonPath("$.message").value("Profile image retrieved successfully"));
//
//        verify(userRepository).findByUsername("testuser");
//    }
//
//    @Test
//    @WithMockUser(username = "testuser")
//    void getProfileImage_WhenNoImage_ShouldReturnNotFound() throws Exception {
//        testUser.setProfileImage(null);
//        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
//
//        mockMvc.perform(get("/user/profile-image"))
//                .andExpect(status().isNotFound())
//                .andExpect(jsonPath("$.hasImage").value("false"))
//                .andExpect(jsonPath("$.message").value("No profile image found"));
//    }
//
//    @Test
//    @WithMockUser(username = "testuser")
//    void deleteProfileImage_WhenImageExists_ShouldReturnOk() throws Exception {
//        byte[] imageData = "test image data".getBytes();
//        testUser.setProfileImage(imageData);
//        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
//        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);
//
//        mockMvc.perform(delete("/user/profile-image")
//                        .with(csrf()))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.message").value("Profile image deleted successfully"))
//                .andExpect(jsonPath("$.hasImage").value("false"));
//
//        verify(userRepository).save(any(ApplicationUser.class));
//    }
//
//    @Test
//    @WithMockUser(username = "testuser")
//    void deleteProfileImage_WhenNoImage_ShouldReturnOk() throws Exception {
//        testUser.setProfileImage(null);
//        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
//
//        mockMvc.perform(delete("/user/profile-image")
//                        .with(csrf()))
//                .andExpect(status().isOk())
//                .andExpect(jsonPath("$.message").value("No profile image found to delete"))
//                .andExpect(jsonPath("$.hasImage").value("false"));
//
//        verify(userRepository, never()).save(any(ApplicationUser.class));
//    }
//
//    @Test
//    void exchangeOAuth2Token_WhenUnsupportedProvider_ShouldReturnBadRequest() throws Exception {
//        String requestBody = "{\"provider\":\"facebook\",\"access_token\":\"token123\"}";
//
//        mockMvc.perform(post("/auth/oauth2/exchange")
//                        .with(csrf())
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(requestBody))
//                .andExpect(status().isBadRequest())
//                .andExpect(jsonPath("$.error").value("Unsupported provider: facebook"));
//    }
//
//    @Test
//    void exchangeOAuth2Token_WhenNoAccessToken_ShouldReturnUnauthorized() throws Exception {
//        String requestBody = "{\"provider\":\"google\",\"access_token\":\"\"}";
//
//        mockMvc.perform(post("/auth/oauth2/exchange")
//                        .with(csrf())
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(requestBody))
//                .andExpect(status().isUnauthorized())
//                .andExpect(jsonPath("$.error").value("Access token is required"));
//    }
//
//    @Test
//    void exchangeOAuth2Token_WhenValidGoogleToken_ShouldReturnOk() throws Exception {
//        String requestBody = "{\"provider\":\"google\",\"access_token\":\"valid-token\"}";
//        when(oauth2TokenService.exchangeGoogleToken("valid-token")).thenReturn(loginResponseDTO);
//
//        mockMvc.perform(post("/auth/oauth2/exchange")
//                        .with(csrf())
//                        .contentType(MediaType.APPLICATION_JSON)
//                        .content(requestBody))
//                .andExpect(status().isOk())
//                .andExpect(content().contentType(MediaType.APPLICATION_JSON))
//                .andExpect(jsonPath("$.user.username").value("testuser"));
//
//        verify(oauth2TokenService).exchangeGoogleToken("valid-token");
//    }
//}
