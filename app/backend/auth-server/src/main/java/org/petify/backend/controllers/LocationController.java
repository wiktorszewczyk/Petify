package org.petify.backend.controllers;

import org.petify.backend.dto.GeolocationRequest;
import org.petify.backend.dto.GeolocationResponse;
import org.petify.backend.dto.UserLocationRequest;
import org.petify.backend.dto.UserLocationResponse;
import org.petify.backend.services.GeocodingService;
import org.petify.backend.services.ProfileAchievementService;
import org.petify.backend.services.UserLocationService;

import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/user/location")
@CrossOrigin("*")
@Slf4j
public class LocationController {

    @Autowired
    private UserLocationService userLocationService;

    @Autowired
    private GeocodingService geocodingService;

    @Autowired
    private ProfileAchievementService profileAchievementService;

    @GetMapping("/")
    public ResponseEntity<UserLocationResponse> getUserLocation(Authentication authentication) {
        String username = authentication.getName();
        UserLocationResponse location = userLocationService.getUserLocation(username);
        return ResponseEntity.ok(location);
    }

    @PutMapping("/")
    public ResponseEntity<?> updateUserLocation(
            Authentication authentication,
            @Valid @RequestBody UserLocationRequest locationRequest) {

        try {
            String username = authentication.getName();
            UserLocationResponse updatedLocation = userLocationService.updateUserLocation(username, locationRequest);

            profileAchievementService.onLocationSet(username);

            log.info("User {} updated location to: {}", username, locationRequest.city());
            return ResponseEntity.ok(updatedLocation);
        } catch (Exception e) {
            log.error("Failed to update location for user {}: {}", authentication.getName(), e.getMessage());

            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Nie można zaktualizować lokalizacji: " + e.getMessage());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    @PostMapping("/set-by-city")
    public ResponseEntity<?> setLocationByCity(
            Authentication authentication,
            @Valid @RequestBody GeolocationRequest request) {

        try {
            String username = authentication.getName();
            GeolocationResponse coords = geocodingService.getCoordinatesForCity(request.cityName());

            UserLocationResponse updatedLocation = userLocationService.setUserLocationByCoordinates(
                    username, coords.cityName(), coords.latitude(), coords.longitude(), 20.0);

            profileAchievementService.onLocationSet(username);

            log.info("User {} set location by city to: {}", username, coords.cityName());
            return ResponseEntity.ok(updatedLocation);

        } catch (Exception e) {
            log.error("Failed to set location by city for user {}: {}", authentication.getName(), e.getMessage());

            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Nie można znaleźć współrzędnych dla miasta: " + request.cityName());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    @PostMapping("/geocode")
    public ResponseEntity<?> geocodeCity(@Valid @RequestBody GeolocationRequest request) {
        try {
            GeolocationResponse location = geocodingService.getCoordinatesForCity(request.cityName());
            return ResponseEntity.ok(location);
        } catch (Exception e) {
            log.error("Failed to geocode city {}: {}", request.cityName(), e.getMessage());

            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Nie można znaleźć współrzędnych dla miasta: " + request.cityName());
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    @GetMapping("/search-cities")
    public ResponseEntity<?> searchCities(@RequestParam String query) {
        try {
            if (query == null || query.trim().length() < 2) {
                Map<String, String> errorResponse = new HashMap<>();
                errorResponse.put("error", "Zapytanie musi mieć co najmniej 2 znaki");
                return ResponseEntity.badRequest().body(errorResponse);
            }

            List<GeolocationResponse> cities = geocodingService.searchCities(query);
            return ResponseEntity.ok(cities);
        } catch (Exception e) {
            log.error("Failed to search cities with query {}: {}", query, e.getMessage());

            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Błąd podczas wyszukiwania miast");
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    @PostMapping("/validate-city")
    public ResponseEntity<?> validateCity(@Valid @RequestBody GeolocationRequest request) {
        try {
            boolean isValid = geocodingService.isCityValid(request.cityName());

            Map<String, Object> response = new HashMap<>();
            response.put("valid", isValid);
            response.put("cityName", request.cityName());

            if (isValid) {
                GeolocationResponse location = geocodingService.getCoordinatesForCity(request.cityName());
                response.put("location", location);
            }

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Failed to validate city {}: {}", request.cityName(), e.getMessage());

            Map<String, Object> response = new HashMap<>();
            response.put("valid", false);
            response.put("cityName", request.cityName());
            response.put("error", e.getMessage());

            return ResponseEntity.ok(response);
        }
    }

    @DeleteMapping("/")
    public ResponseEntity<?> clearUserLocation(Authentication authentication) {
        try {
            String username = authentication.getName();
            UserLocationResponse clearedLocation = userLocationService.clearUserLocation(username);

            log.info("User {} cleared location", username);
            return ResponseEntity.ok(clearedLocation);
        } catch (Exception e) {
            log.error("Failed to clear location for user {}: {}", authentication.getName(), e.getMessage());

            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Nie można wyczyścić lokalizacji");
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    @GetMapping("/search-distances")
    public ResponseEntity<List<Map<String, Object>>> getSearchDistances() {
        List<Map<String, Object>> distances = List.of(
                Map.of("value", 5.0, "label", "5 km", "description", "Bardzo blisko"),
                Map.of("value", 10.0, "label", "10 km", "description", "Blisko"),
                Map.of("value", 20.0, "label", "20 km", "description", "W okolicy (domyślne)"),
                Map.of("value", 50.0, "label", "50 km", "description", "W regionie"),
                Map.of("value", 100.0, "label", "100 km", "description", "W województwie"),
                Map.of("value", -1.0, "label", "Bez ograniczeń", "description", "Cała Polska")
        );

        return ResponseEntity.ok(distances);
    }

    @GetMapping("/stats")
    public ResponseEntity<?> getLocationStats(Authentication authentication) {
        try {
            String username = authentication.getName();
            UserLocationResponse location = userLocationService.getUserLocation(username);

            Map<String, Object> stats = new HashMap<>();
            stats.put("hasLocation", location.hasLocation());
            stats.put("hasCompleteProfile", location.hasCompleteLocationProfile());
            stats.put("city", location.city());
            stats.put("preferredDistance", location.preferredSearchDistanceKm());
            stats.put("autoLocationEnabled", location.autoLocationEnabled());
            stats.put("lastUpdated", location.locationUpdatedAt());

            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            log.error("Failed to get location stats for user {}: {}", authentication.getName(), e.getMessage());

            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Nie można pobrać statystyk lokalizacji");
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }

    @GetMapping("/by-username")
    public ResponseEntity<UserLocationResponse> getUserLocationByUsername(
            @RequestParam String username,
            @RequestHeader("Authorization") String token) {
        UserLocationResponse location = userLocationService.getUserLocation(username);
        return ResponseEntity.ok(location);
    }

    @GetMapping("/has-location")
    public ResponseEntity<Boolean> userHasLocationByUsername(
            @RequestParam String username,
            @RequestHeader("Authorization") String token) {

        boolean hasLocation = userLocationService.userHasLocation(username);
        return ResponseEntity.ok(hasLocation);
    }

    @GetMapping("/preferences")
    public ResponseEntity<?> getUserLocationPreferences(Authentication authentication) {
        try {
            String username = authentication.getName();
            Double preferredDistance = userLocationService.getUserPreferredSearchDistance(username);

            Map<String, Object> preferences = new HashMap<>();
            preferences.put("preferredSearchDistanceKm", preferredDistance);
            preferences.put("username", username);

            return ResponseEntity.ok(preferences);
        } catch (Exception e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", "Nie można pobrać preferencji użytkownika");
            return ResponseEntity.badRequest().body(errorResponse);
        }
    }
}
