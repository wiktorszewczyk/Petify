package org.petify.backend.controllers;

import jakarta.servlet.http.HttpServletResponse;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.dto.LoginRequestDTO;
import org.petify.backend.dto.LoginResponseDTO;
import org.petify.backend.dto.RegistrationDTO;
import org.petify.backend.repository.UserRepository;
import org.petify.backend.services.AuthenticationService;
import org.petify.backend.services.TokenService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * Controller handling all authentication, authorization and user management endpoints,
 * both for form login and OAuth2
 */
@RestController
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class AuthenticationController {

    @Autowired
    private AuthenticationService authenticationService;

    @Autowired
    private TokenService tokenService;

    @Autowired
    private UserRepository userRepository;

    /**
     * ===== Authentication Endpoints =====
     */

    @PostMapping("/auth/register")
    public ResponseEntity<?> registerUser(@Valid @RequestBody RegistrationDTO registrationDTO) {
        try {
            ApplicationUser user = authenticationService.registerUser(registrationDTO);

            user.setPassword(null);

            Map<String, Object> response = new HashMap<>();
            response.put("user", user);
            response.put("message", "User registered successfully");

            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException e) {
            Map<String, String> response = new HashMap<>();
            response.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        } catch (Exception e) {
            Map<String, String> response = new HashMap<>();
            response.put("error", "Registration failed: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PostMapping("/auth/login")
    public ResponseEntity<?> loginUser(@Valid @RequestBody LoginRequestDTO loginRequest) {
        LoginResponseDTO response = authenticationService.loginUser(loginRequest);

        if (response.getUser() == null) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Invalid credentials");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        return ResponseEntity.ok(response);
    }

    /**
     * JWT Token validation endpoint
     *
     * @param authHeader Authorization header with JWT token
     * @return Token validation status
     */
    @PostMapping("/auth/token/validate")
    public ResponseEntity<?> validateToken(@RequestHeader("Authorization") String authHeader) {
        try {
            // Extract token from Bearer header
            String token = authHeader.substring(7); // Remove "Bearer " from beginning

            // Check if token is valid
            var jwt = tokenService.validateJwt(token);

            // If we get here, token is valid
            Map<String, Object> response = new HashMap<>();
            response.put("valid", true);
            response.put("subject", jwt.getSubject());
            response.put("expires", jwt.getExpiresAt());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("valid", false);
            response.put("error", e.getMessage());

            return ResponseEntity.status(401).body(response);
        }
    }

    /**
     * ===== OAuth2 endpoints =====
     */

    /**
     * Initiate Google OAuth2 login process
     * Spring Security will handle redirecting to Google login page
     *
     * @return Redirect to Google authorization
     */
    @GetMapping("/auth/oauth2/google")
    public void initiateGoogleLogin(HttpServletResponse response) throws IOException, IOException {
        response.sendRedirect("/oauth2/authorization/google");
    }

    /**
     * Get information about logged in OAuth2 user
     *
     * @param principal Information about logged in OAuth2 user
     * @return Map of user data
     */
    @GetMapping("/auth/oauth2/user-info")
    public Map<String, Object> getUserInfo(@AuthenticationPrincipal OAuth2User principal) {
        Map<String, Object> userInfo = new HashMap<>();

        if (principal != null) {
            userInfo.put("name", principal.getAttribute("name"));
            userInfo.put("email", principal.getAttribute("email"));
            userInfo.put("picture", principal.getAttribute("picture"));
            userInfo.put("locale", principal.getAttribute("locale"));
        }

        return userInfo;
    }

    /**
     * Generate JWT token for logged in OAuth2 user
     *
     * @param authentication Authentication object
     * @return Map containing JWT token or error message
     */
    @GetMapping("/auth/oauth2/token")
    public Map<String, String> getOAuth2Token(Authentication authentication) {
        Map<String, String> response = new HashMap<>();

        if (authentication != null && authentication.isAuthenticated()) {
            String token = tokenService.generateJwt(authentication);
            response.put("token", token);
        } else {
            response.put("error", "User is not authenticated");
        }

        return response;
    }

    /**
     * Handle successful OAuth2 login (e.g., Google)
     *
     * @param token JWT Token passed from OAuth2 login success handler
     * @param oauth2User Information about logged in OAuth2 user
     * @return User data and JWT token
     */
    @GetMapping("/auth/oauth2/success")
    public ResponseEntity<Map<String, Object>> oauthLoginSuccess(
            @RequestParam String token,
            @AuthenticationPrincipal OAuth2User oauth2User) {

        String email = oauth2User.getAttribute("email");
        ApplicationUser user = userRepository.findByUsername(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Map<String, Object> response = new HashMap<>();
        response.put("user", user);
        response.put("jwt", token);

        return ResponseEntity.ok(response);
    }

    /**
     * Handle OAuth2 login error
     *
     * @return Error information
     */
    @GetMapping("/auth/oauth2/error")
    public ResponseEntity<Map<String, String>> oauthLoginError() {
        Map<String, String> response = new HashMap<>();
        response.put("error", "OAuth2 authentication failed");
        return ResponseEntity.badRequest().body(response);
    }

    /**
     * ===== User Management Endpoints =====
     */

    /**
     * Get user data endpoint
     *
     * @param authentication Authentication object
     * @return User data
     */
    @GetMapping("/user")
    public ResponseEntity<?> getUserData(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "User not authenticated");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        ApplicationUser user = userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Remove sensitive information
        user.setPassword(null);

        return ResponseEntity.ok(user);
    }

    /**
     * Update user data endpoint
     */
    @PutMapping("/user")
    public ResponseEntity<?> updateUserData(
            Authentication authentication,
            @RequestBody ApplicationUser userData) {

        if (authentication == null || !authentication.isAuthenticated()) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "User not authenticated");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        try {
            ApplicationUser updatedUser = authenticationService.updateUserProfile(
                    authentication.getName(), userData);

            // Remove sensitive information
            updatedUser.setPassword(null);

            return ResponseEntity.ok(updatedUser);
        } catch (IllegalArgumentException e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to update user data: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Delete user account endpoint
     */
    @DeleteMapping("/user")
    public ResponseEntity<?> deleteUser(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "User not authenticated");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        try {
            authenticationService.deleteUserAccount(authentication.getName());

            Map<String, String> response = new HashMap<>();
            response.put("message", "User account successfully deleted");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to delete user account: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    /**
     * Self-deactivate account endpoint
     */
    @PostMapping("/user/deactivate")
    public ResponseEntity<?> selfDeactivateAccount(
            Authentication authentication,
            @RequestParam(required = false) String reason) {

        if (authentication == null || !authentication.isAuthenticated()) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "User not authenticated");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        try {
            ApplicationUser user = authenticationService.selfDeactivateAccount(
                    authentication.getName(), reason);

            Map<String, String> response = new HashMap<>();
            response.put("message", "Your account has been deactivated successfully");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Failed to deactivate account: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
}