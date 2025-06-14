package org.petify.backend.services;

import org.petify.backend.repository.UserRepository;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Slf4j
public class VolunteerAchievementService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AchievementService achievementService;

    @Transactional
    public void onVolunteerApplicationSubmitted(String username) {
        try {
            achievementService.trackVolunteerAchievementByName(username, "Ochotnik");

            log.info("Volunteer achievement awarded to user: {}", username);
        } catch (Exception e) {
            log.error("Error awarding volunteer achievement for user {}: {}", username, e.getMessage());
        }
    }

    @Transactional
    public void onVolunteerApproved(String username) {
        try {
            log.info("Volunteer approved for user: {}", username);
        } catch (Exception e) {
            log.error("Error processing volunteer approval for user {}: {}", username, e.getMessage());
        }
    }
}
