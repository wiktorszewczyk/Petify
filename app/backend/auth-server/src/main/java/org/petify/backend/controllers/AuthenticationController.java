package org.petify.backend.controllers;

import org.petify.backend.dto.LoginRequestDTO;
import org.petify.backend.dto.LoginResponseDTO;
import org.petify.backend.dto.RegistrationDTO;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.repository.UserRepository;
import org.petify.backend.services.AuthenticationService;
import org.petify.backend.services.OAuth2TokenService;
import org.petify.backend.services.TokenService;

import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

@RestController
@CrossOrigin(origins = "*", allowedHeaders = "*")
@Transactional
public class AuthenticationController {

    private static final String USER_NOT_AUTHENTICATED = "User not authenticated";
    private static final String USER_NOT_FOUND = "User not found";
    private static final String ERROR_KEY = "error";
    private static final String MESSAGE_KEY = "message";
    private static final long MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
    private static final Set<String> ALLOWED_IMAGE_TYPES = Set.of(
            "image/jpeg", "image/png", "image/gif", "image/webp"
    );

    @Autowired
    private AuthenticationService authenticationService;

    @Autowired
    private TokenService tokenService;

    @Autowired
    private OAuth2TokenService oauth2TokenService;

    @Autowired
    private UserRepository userRepository;

    private ResponseEntity<?> createUnauthorizedResponse() {
        Map<String, String> errorResponse = new HashMap<>();
        errorResponse.put(ERROR_KEY, USER_NOT_AUTHENTICATED);
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
    }

    private ApplicationUser getAuthenticatedUser(Authentication authentication) {
        return userRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new RuntimeException(USER_NOT_FOUND));
    }

    @PostMapping("/auth/register")
    public ResponseEntity<?> registerUser(@Valid @RequestBody RegistrationDTO registrationDTO) {
        try {
            ApplicationUser user = authenticationService.registerUser(registrationDTO);

            Map<String, Object> response = new HashMap<>();
            response.put("user", user);
            response.put(MESSAGE_KEY, "User registered successfully");

            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (IllegalArgumentException e) {
            Map<String, String> response = new HashMap<>();
            response.put(ERROR_KEY, e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        } catch (Exception e) {
            Map<String, String> response = new HashMap<>();
            response.put(ERROR_KEY, "Registration failed: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    @PostMapping("/auth/login")
    public ResponseEntity<?> loginUser(@Valid @RequestBody LoginRequestDTO loginRequest) {
        LoginResponseDTO response = authenticationService.loginUser(loginRequest);

        if (response.getUser() == null) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put(ERROR_KEY, "Invalid credentials");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        return ResponseEntity.ok(response);
    }

    @PostMapping("/auth/token/validate")
    public ResponseEntity<?> validateToken(@RequestHeader("Authorization") String authHeader) {
        try {
            String token = authHeader.substring(7);

            var jwt = tokenService.validateJwt(token);

            Map<String, Object> response = new HashMap<>();
            response.put("valid", true);
            response.put("subject", jwt.getSubject());
            response.put("expires", jwt.getExpiresAt());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("valid", false);
            response.put(ERROR_KEY, e.getMessage());

            return ResponseEntity.status(401).body(response);
        }
    }

    @GetMapping("/auth/oauth2/google")
    public void initiateGoogleLogin(HttpServletResponse response) throws IOException {
        response.sendRedirect("/oauth2/authorization/google");
    }

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

    @GetMapping("/auth/oauth2/token")
    public Map<String, String> getOAuth2Token(Authentication authentication) {
        Map<String, String> response = new HashMap<>();

        if (authentication != null && authentication.isAuthenticated()) {
            String token = tokenService.generateJwt(authentication);
            response.put("token", token);
        } else {
            response.put(ERROR_KEY, USER_NOT_AUTHENTICATED);
        }

        return response;
    }

    @GetMapping("/auth/oauth2/success")
    public void oauthLoginSuccess(
            @RequestParam String token,
            @AuthenticationPrincipal OAuth2User oauth2User,
            HttpServletResponse response) throws IOException {

        String email = oauth2User.getAttribute("email");
        ApplicationUser user = userRepository.findByUsername(email)
                .orElseThrow(() -> new RuntimeException(USER_NOT_FOUND));

        String frontendUrl = "http://localhost:5173/home?token=" + token + "&userId=" + user.getUserId();
        response.sendRedirect(frontendUrl);
    }

    @GetMapping("/auth/oauth2/error")
    public void oauthLoginError(HttpServletResponse response) throws IOException {
        String frontendUrl = "http://localhost:5173/home?error=OAuth2%20authentication%20failed";
        response.sendRedirect(frontendUrl);
    }

    @PostMapping("/auth/oauth2/exchange")
    public ResponseEntity<?> exchangeOAuth2Token(@RequestBody Map<String, String> request) {
        String provider = request.get("provider");
        String accessToken = request.get("access_token");

        if (!"google".equals(provider)) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Unsupported provider: " + provider);
            return ResponseEntity.badRequest().body(errorResponse);
        }

        if (accessToken == null || accessToken.trim().isEmpty()) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Access token is required");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }

        LoginResponseDTO response = oauth2TokenService.exchangeGoogleToken(accessToken);
        if (response.getUser() == null) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Invalid Google access token");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(errorResponse);
        }
        return ResponseEntity.ok(response);
    }

    @GetMapping("/user")
    public ResponseEntity<?> getUserData(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return createUnauthorizedResponse();
        }

        ApplicationUser user = getAuthenticatedUser(authentication);
        return ResponseEntity.ok(user);
    }

    @PutMapping("/user")
    public ResponseEntity<?> updateUserData(
            Authentication authentication,
            @RequestBody ApplicationUser userData) {

        if (authentication == null || !authentication.isAuthenticated()) {
            return createUnauthorizedResponse();
        }

        try {
            ApplicationUser updatedUser = authenticationService.updateUserProfile(
                    authentication.getName(), userData);

            return ResponseEntity.ok(updatedUser);
        } catch (IllegalArgumentException e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put(ERROR_KEY, e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put(ERROR_KEY, "Failed to update user data: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @DeleteMapping("/user")
    public ResponseEntity<?> deleteUser(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return createUnauthorizedResponse();
        }

        try {
            authenticationService.deleteUserAccount(authentication.getName());

            Map<String, String> response = new HashMap<>();
            response.put(MESSAGE_KEY, "User account successfully deleted");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put(ERROR_KEY, "Failed to delete user account: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @PostMapping("/user/deactivate")
    public ResponseEntity<?> selfDeactivateAccount(
            Authentication authentication,
            @RequestParam(required = false) String reason) {

        if (authentication == null || !authentication.isAuthenticated()) {
            return createUnauthorizedResponse();
        }

        try {
            authenticationService.selfDeactivateAccount(authentication.getName(), reason);

            Map<String, String> response = new HashMap<>();
            response.put(MESSAGE_KEY, "Your account has been deactivated successfully");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put(ERROR_KEY, "Failed to deactivate account: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    private void validateImageFile(MultipartFile image) {
        if (image.isEmpty()) {
            throw new IllegalArgumentException("Image file is empty");
        }

        if (image.getSize() > MAX_IMAGE_SIZE) {
            throw new IllegalArgumentException("Image file too large. Maximum size is 5MB");
        }

        String contentType = image.getContentType();
        if (contentType == null || !ALLOWED_IMAGE_TYPES.contains(contentType)) {
            throw new IllegalArgumentException("Unsupported image format. Allowed: JPEG, PNG, GIF, WebP");
        }
    }

    @PostMapping("/user/profile-image")
    @Transactional
    public ResponseEntity<?> uploadProfileImage(
            Authentication authentication,
            @RequestPart("image") MultipartFile image) {

        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of(ERROR_KEY, USER_NOT_AUTHENTICATED));
        }

        try {
            validateImageFile(image);

            ApplicationUser user = getAuthenticatedUser(authentication);

            user.setProfileImage(image.getBytes());
            userRepository.save(user);

            return ResponseEntity.ok(Map.of(
                    MESSAGE_KEY, "Profile image uploaded successfully",
                    "imageSize", image.getSize(),
                    "imageType", image.getContentType(),
                    "hasImage", true
            ));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest()
                    .body(Map.of(ERROR_KEY, e.getMessage()));
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(ERROR_KEY, "Failed to process image file: " + e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of(ERROR_KEY, "Failed to upload image: " + e.getMessage()));
        }
    }

    @GetMapping("/user/profile-image")
    @Transactional(readOnly = true)
    public ResponseEntity<?> getProfileImage(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return createUnauthorizedResponse();
        }

        try {
            ApplicationUser user = getAuthenticatedUser(authentication);

            if (user.getProfileImage() == null || user.getProfileImage().length == 0) {
                Map<String, String> response = new HashMap<>();
                response.put(MESSAGE_KEY, "No profile image found");
                response.put("hasImage", "false");
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
            }

            String base64Image = Base64.getEncoder().encodeToString(user.getProfileImage());

            Map<String, Object> response = new HashMap<>();
            response.put("image", "data:image/jpeg;base64," + base64Image);
            response.put("imageSize", user.getProfileImage().length);
            response.put("hasImage", "true");
            response.put(MESSAGE_KEY, "Profile image retrieved successfully");

            return ResponseEntity.ok()
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(response);

        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put(ERROR_KEY, "Failed to retrieve profile image: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @DeleteMapping("/user/profile-image")
    @Transactional
    public ResponseEntity<?> deleteProfileImage(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return createUnauthorizedResponse();
        }

        try {
            ApplicationUser user = getAuthenticatedUser(authentication);

            if (user.getProfileImage() == null || user.getProfileImage().length == 0) {
                Map<String, String> response = new HashMap<>();
                response.put(MESSAGE_KEY, "No profile image found to delete");
                response.put("hasImage", "false");
                return ResponseEntity.ok(response);
            }

            final int deletedImageSize = user.getProfileImage().length;
            user.setProfileImage(null);
            userRepository.save(user);

            Map<String, Object> response = new HashMap<>();
            response.put(MESSAGE_KEY, "Profile image deleted successfully");
            response.put("deletedImageSize", deletedImageSize);
            response.put("hasImage", "false");
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put(ERROR_KEY, "Failed to delete profile image: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }
}
