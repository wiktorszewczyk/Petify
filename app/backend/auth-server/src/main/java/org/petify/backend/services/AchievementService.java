package org.petify.backend.services;

import org.petify.backend.models.*;
import org.petify.backend.repository.AchievementRepository;
import org.petify.backend.repository.UserAchievementRepository;
import org.petify.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class AchievementService {

    @Autowired
    private AchievementRepository achievementRepository;

    @Autowired
    private UserAchievementRepository userAchievementRepository;

    @Autowired
    private UserRepository userRepository;

    public List<UserAchievement> getUserAchievements(String username) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return userAchievementRepository.findByUser(user);
    }

    @Transactional
    public UserAchievement trackAchievementProgress(String username, Long achievementId, int progressIncrement) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Achievement achievement = achievementRepository.findById(achievementId)
                .orElseThrow(() -> new RuntimeException("Achievement not found"));

        UserAchievement userAchievement = userAchievementRepository
                .findByUserAndAchievementId(user, achievementId)
                .orElseGet(() -> {
                    UserAchievement newAchievement = new UserAchievement();
                    newAchievement.setUser(user);
                    newAchievement.setAchievement(achievement);
                    newAchievement.setCurrentProgress(0);
                    return newAchievement;
                });

        if (userAchievement.getCompleted()) {
            return userAchievement;
        }

        int newProgress = userAchievement.getCurrentProgress() + progressIncrement;
        userAchievement.setCurrentProgress(newProgress);

        if (newProgress >= achievement.getRequiredActions()) {
            userAchievement.setCompleted(true);
            userAchievement.setCompletionDate(LocalDateTime.now());

            user.setXpPoints(user.getXpPoints() + achievement.getXpReward());

            updateBadgeCounts(user, achievement.getCategory());

            updateUserLevel(user);

            userRepository.save(user);
        }

        return userAchievementRepository.save(userAchievement);
    }

    private void updateBadgeCounts(ApplicationUser user, AchievementCategory category) {
        switch (category) {
            case LIKES:
                user.setLikesCount(user.getLikesCount() + 1);
                break;
            case SUPPORT:
                user.setSupportCount(user.getSupportCount() + 1);
                break;
            case BADGE:
                user.setBadgesCount(user.getBadgesCount() + 1);
                break;
        }
    }

    private void updateUserLevel(ApplicationUser user) {
        int xp = user.getXpPoints();

        int newLevel = 1 + (xp / 250);

        if (newLevel > user.getLevel()) {
            user.setLevel(newLevel);
        }
    }

    public Map<String, Object> getUserLevelInfo(String username) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Map<String, Object> levelInfo = new HashMap<>();
        levelInfo.put("level", user.getLevel());
        levelInfo.put("xpPoints", user.getXpPoints());
        levelInfo.put("xpToNextLevel", user.getXpToNextLevel());
        levelInfo.put("likesCount", user.getLikesCount());
        levelInfo.put("supportCount", user.getSupportCount());
        levelInfo.put("badgesCount", user.getBadgesCount());

        return levelInfo;
    }

    @Transactional
    public void initializeUserAchievements(ApplicationUser user) {
        List<Achievement> allAchievements = achievementRepository.findAll();

        for (Achievement achievement : allAchievements) {
            UserAchievement userAchievement = new UserAchievement();
            userAchievement.setUser(user);
            userAchievement.setAchievement(achievement);
            userAchievement.setCurrentProgress(0);
            userAchievement.setCompleted(false);

            userAchievementRepository.save(userAchievement);
        }
    }
}