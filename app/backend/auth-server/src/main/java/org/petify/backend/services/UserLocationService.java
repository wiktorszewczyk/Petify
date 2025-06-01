package org.petify.backend.services;

import org.petify.backend.dto.UserLocationRequest;
import org.petify.backend.dto.UserLocationResponse;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.repository.UserRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@Transactional
public class UserLocationService {

    @Autowired
    private UserRepository userRepository;

    /**
     * Pobiera lokalizację użytkownika
     */
    public UserLocationResponse getUserLocation(String username) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return new UserLocationResponse(
                user.getCity(),
                user.getLatitude(),
                user.getLongitude(),
                user.getPreferredSearchDistanceKm(),
                user.getAutoLocationEnabled(),
                user.getLocationUpdatedAt(),
                user.hasLocation(),
                user.hasCompleteLocationProfile()
        );
    }

    /**
     * Aktualizuje lokalizację użytkownika
     */
    public UserLocationResponse updateUserLocation(String username, UserLocationRequest locationRequest) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (locationRequest.city() != null) {
            user.setCity(locationRequest.city().trim());
        }

        if (locationRequest.latitude() != null && locationRequest.longitude() != null) {
            user.setLatitude(locationRequest.latitude());
            user.setLongitude(locationRequest.longitude());
        }

        if (locationRequest.preferredSearchDistanceKm() != null) {
            user.setPreferredSearchDistanceKm(locationRequest.preferredSearchDistanceKm());
        }

        if (locationRequest.autoLocationEnabled() != null) {
            user.setAutoLocationEnabled(locationRequest.autoLocationEnabled());
        }

        user.setLocationUpdatedAt(LocalDateTime.now());

        ApplicationUser savedUser = userRepository.save(user);

        return new UserLocationResponse(
                savedUser.getCity(),
                savedUser.getLatitude(),
                savedUser.getLongitude(),
                savedUser.getPreferredSearchDistanceKm(),
                savedUser.getAutoLocationEnabled(),
                savedUser.getLocationUpdatedAt(),
                savedUser.hasLocation(),
                savedUser.hasCompleteLocationProfile()
        );
    }

    /**
     * Ustawia lokalizację użytkownika na podstawie współrzędnych
     */
    public UserLocationResponse setUserLocationByCoordinates(String username, String city,
                                                             Double latitude, Double longitude,
                                                             Double preferredDistance) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setLocation(city, latitude, longitude);

        if (preferredDistance != null) {
            user.setPreferredSearchDistanceKm(preferredDistance);
        }

        ApplicationUser savedUser = userRepository.save(user);

        return new UserLocationResponse(
                savedUser.getCity(),
                savedUser.getLatitude(),
                savedUser.getLongitude(),
                savedUser.getPreferredSearchDistanceKm(),
                savedUser.getAutoLocationEnabled(),
                savedUser.getLocationUpdatedAt(),
                savedUser.hasLocation(),
                savedUser.hasCompleteLocationProfile()
        );
    }

    /**
     * Czyści lokalizację użytkownika
     */
    public UserLocationResponse clearUserLocation(String username) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.clearLocation();
        user.setAutoLocationEnabled(false);

        ApplicationUser savedUser = userRepository.save(user);

        return new UserLocationResponse(
                null,
                null,
                null,
                savedUser.getPreferredSearchDistanceKm(),
                false,
                null,
                false,
                false
        );
    }

    /**
     * Sprawdza czy użytkownik ma ustawioną lokalizację
     */
    public boolean userHasLocation(String username) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return user.hasLocation();
    }

    /**
     * Pobiera domyślną odległość wyszukiwania użytkownika
     */
    public Double getUserPreferredSearchDistance(String username) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return user.getPreferredSearchDistanceKm() != null
                ? user.getPreferredSearchDistanceKm() : 20.0;
    }
}
