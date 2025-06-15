package org.petify.backend.controllers;

import org.petify.backend.models.UserAchievement;
import org.petify.backend.services.AchievementService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/user/achievements")
@CrossOrigin("*")
public class AchievementController {

    @Autowired
    private AchievementService achievementService;

    @GetMapping("/")
    public ResponseEntity<List<UserAchievement>> getUserAchievements() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();

        List<UserAchievement> achievements = achievementService.getUserAchievements(username);
        return ResponseEntity.ok(achievements);
    }

    @GetMapping("/level")
    public ResponseEntity<Map<String, Object>> getUserLevelInfo() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();

        Map<String, Object> levelInfo = achievementService.getUserLevelInfo(username);
        return ResponseEntity.ok(levelInfo);
    }

    @PostMapping("/{achievementId}/progress")
    public ResponseEntity<UserAchievement> trackAchievementProgress(
            @PathVariable Long achievementId,
            @RequestParam int progress) {

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();

        UserAchievement userAchievement = achievementService.trackAchievementProgress(
                username, achievementId, progress);

        return ResponseEntity.ok(userAchievement);
    }

    @PostMapping("/track-like")
    public ResponseEntity<Void> trackLikeProgress() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();

        achievementService.trackLikeAchievements(username);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/track-support")
    public ResponseEntity<Void> trackSupportProgress() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();

        achievementService.trackSupportAchievements(username);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/track-volunteer")
    public ResponseEntity<Void> trackVolunteerProgress() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();

        achievementService.trackVolunteerAchievements(username);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/track-adoption")
    public ResponseEntity<Void> trackAdoptionProgress() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();

        achievementService.trackAdoptionAchievements(username);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/track-adoption/{username}")
    public ResponseEntity<Void> trackAdoptionProgressForUser(@PathVariable String username) {
        achievementService.trackAdoptionAchievements(username);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/add-donation-xp")
    public ResponseEntity<Void> addDonationExperiencePoints(@RequestParam int xpPoints) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();

        achievementService.addExperiencePointsForDonation(username, xpPoints);
        return ResponseEntity.ok().build();
    }
}
