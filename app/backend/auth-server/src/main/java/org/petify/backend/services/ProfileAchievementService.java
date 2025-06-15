package org.petify.backend.services;

import org.petify.backend.models.ApplicationUser;
import org.petify.backend.repository.UserRepository;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Slf4j
public class ProfileAchievementService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AchievementService achievementService;

    @Transactional
    public void checkAndAwardProfileAchievements(String username) {
        try {
            ApplicationUser user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("User not found: " + username));

            checkProfilePictureAchievement(user);
            checkLocationAchievement(user);
            checkCompleteProfileAchievement(user);

        } catch (Exception e) {
            log.error("Error checking profile achievements for user {}: {}", username, e.getMessage());
        }
    }

    @Transactional
    public void checkProfilePictureAchievement(ApplicationUser user) {
        if (user.hasProfileImage()) {
            try {
                achievementService.trackProfileAchievementByName(user.getUsername(), "Pierwsza fotka");
                log.debug("Checked profile picture achievement for user: {}", user.getUsername());
            } catch (Exception e) {
                log.error("Error awarding profile picture achievement for user {}: {}", user.getUsername(), e.getMessage());
            }
        }
    }

    @Transactional
    public void checkLocationAchievement(ApplicationUser user) {
        if (user.hasLocation()) {
            try {
                achievementService.trackProfileAchievementByName(user.getUsername(), "Lokalizacja ustawiona");
                log.debug("Checked location achievement for user: {}", user.getUsername());
            } catch (Exception e) {
                log.error("Error awarding location achievement for user {}: {}", user.getUsername(), e.getMessage());
            }
        }
    }

    @Transactional
    public void checkCompleteProfileAchievement(ApplicationUser user) {
        if (isProfileComplete(user)) {
            try {
                achievementService.trackProfileAchievementByName(user.getUsername(), "Kompletny profil");
                log.debug("Checked complete profile achievement for user: {}", user.getUsername());
            } catch (Exception e) {
                log.error("Error awarding complete profile achievement for user {}: {}", user.getUsername(), e.getMessage());
            }
        }
    }

    private boolean isProfileComplete(ApplicationUser user) {
        return user.getFirstName() != null
                && !user.getFirstName().trim().isEmpty()
                && user.getLastName() != null
                && !user.getLastName().trim().isEmpty()
                && user.getEmail() != null
                && !user.getEmail().trim().isEmpty()
                && user.getPhoneNumber() != null
                && !user.getPhoneNumber().trim().isEmpty()
                && user.getBirthDate() != null
                && user.getGender() != null
                && !user.getGender().trim().isEmpty()
                && user.hasProfileImage()
                && user.hasLocation();
    }

    @Transactional
    public void onProfileUpdated(String username) {
        checkAndAwardProfileAchievements(username);
    }

    @Transactional
    public void onProfileImageAdded(String username) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found: " + username));

        checkProfilePictureAchievement(user);
        checkCompleteProfileAchievement(user);
    }

    @Transactional
    public void onLocationSet(String username) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found: " + username));

        checkLocationAchievement(user);
        checkCompleteProfileAchievement(user);
    }
}
