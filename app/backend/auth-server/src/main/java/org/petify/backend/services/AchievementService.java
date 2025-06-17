package org.petify.backend.services;

import org.petify.backend.models.Achievement;
import org.petify.backend.models.AchievementCategory;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.UserAchievement;
import org.petify.backend.repository.AchievementRepository;
import org.petify.backend.repository.UserAchievementRepository;
import org.petify.backend.repository.UserRepository;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@Slf4j
public class AchievementService {

    @Autowired
    private AchievementRepository achievementRepository;

    @Autowired
    private UserAchievementRepository userAchievementRepository;

    @Autowired
    private UserRepository userRepository;

    @Transactional(readOnly = true)
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

            log.info("User {} completed achievement: {} (+{} XP)",
                    username, achievement.getName(), achievement.getXpReward());
        }

        return userAchievementRepository.save(userAchievement);
    }

    @Transactional
    public void trackLikeAchievements(String username) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setLikesCount(user.getLikesCount() + 1);
        userRepository.save(user);

        List<Achievement> likeAchievements = achievementRepository.findByCategory(AchievementCategory.LIKES);

        for (Achievement achievement : likeAchievements) {
            trackAchievementProgress(username, achievement.getId(), 1);
        }
        log.info("Tracked like achievements for user {} - new like count: {}",
                username, user.getLikesCount());
    }

    @Transactional
    public void trackSupportAchievements(String username) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setSupportCount(user.getSupportCount() + 1);
        userRepository.save(user);

        List<Achievement> supportAchievements = achievementRepository.findByCategory(AchievementCategory.SUPPORT);

        for (Achievement achievement : supportAchievements) {
            trackAchievementProgress(username, achievement.getId(), 1);
        }

        log.info("Tracked support achievements for user {} - new support count: {}",
                username, user.getSupportCount());
    }

    @Transactional
    public void trackProfileAchievementByName(String username, String achievementName) {
        trackAchievementByNameAndCategory(username, achievementName, AchievementCategory.PROFILE);
    }

    private void updateBadgeCounts(ApplicationUser user, AchievementCategory category) {
        switch (category) {
            case LIKES:
                break;
            case SUPPORT:
                break;
            case ADOPTION:
                user.setAdoptionCount(user.getAdoptionCount() + 1);
                user.setBadgesCount(user.getBadgesCount() + 1);
                break;
            case BADGE:
            case PROFILE:
            case VOLUNTEER:
                user.setBadgesCount(user.getBadgesCount() + 1);
                break;
            default:
                break;
        }
    }

    private void updateUserLevel(ApplicationUser user) {
        int xp = user.getXpPoints();
        int newLevel = (xp / 100) + 1;

        if (newLevel > user.getLevel()) {
            int oldLevel = user.getLevel();
            user.setLevel(newLevel);
            log.info("User {} leveled up from {} to {}! (Total XP: {})",
                    user.getUsername(), oldLevel, newLevel, xp);
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
        levelInfo.put("adoptionCount", user.getAdoptionCount());

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

    @Transactional
    public void trackVolunteerAchievements(String username) {
        List<Achievement> volunteerAchievements = achievementRepository.findByCategory(AchievementCategory.VOLUNTEER);

        for (Achievement achievement : volunteerAchievements) {
            trackAchievementProgress(username, achievement.getId(), 1);
        }
    }

    @Transactional
    public void trackVolunteerAchievementByName(String username, String achievementName) {
        trackAchievementByNameAndCategory(username, achievementName, AchievementCategory.VOLUNTEER);
    }

    private void trackAchievementByNameAndCategory(String username, String achievementName, AchievementCategory category) {
        try {
            List<Achievement> achievements = achievementRepository.findByCategory(category);

            Optional<Achievement> achievement = achievements.stream()
                    .filter(a -> a.getName().equals(achievementName))
                    .findFirst();

            if (achievement.isPresent()) {
                ApplicationUser user = userRepository.findByUsername(username)
                        .orElseThrow(() -> new RuntimeException("User not found"));

                Optional<UserAchievement> existingUserAchievement = userAchievementRepository
                        .findByUserAndAchievementId(user, achievement.get().getId());

                if (existingUserAchievement.isEmpty() || !existingUserAchievement.get().getCompleted()) {
                    trackAchievementProgress(username, achievement.get().getId(), 1);
                }
            } else {
                log.warn("Achievement with name '{}' not found in {} category", achievementName, category);
            }
        } catch (Exception e) {
            log.error("Error tracking {} achievement '{}' for user {}: {}",
                    category, achievementName, username, e.getMessage());
        }
    }

    @Transactional
    public void trackAdoptionAchievements(String username) {
        List<Achievement> adoptionAchievements = achievementRepository.findByCategory(AchievementCategory.ADOPTION);

        for (Achievement achievement : adoptionAchievements) {
            trackAchievementProgress(username, achievement.getId(), 1);
        }
    }

    @Transactional
    public void addExperiencePointsForDonation(String username, int xpPoints) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        user.setXpPoints(user.getXpPoints() + xpPoints);
        updateUserLevel(user);
        userRepository.save(user);

        log.info("Added {} XP to user {} for donation (Total XP: {})", 
                xpPoints, username, user.getXpPoints());
    }
}
