package org.petify.shelter.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@FeignClient(name = "auth-service", path = "/user/achievements")
public interface AchievementClient {

    @PostMapping("/{achievementId}/progress")
    void trackAchievementProgress(
            @PathVariable Long achievementId,
            @RequestParam int progress
    );

    @PostMapping("/track-like")
    void trackLikeProgress();

    @PostMapping("/track-support")
    void trackSupportProgress();

    @PostMapping("/track-adoption")
    void trackAdoptionProgress();

    @PostMapping("/track-adoption/{username}")
    void trackAdoptionProgressForUser(@PathVariable String username);

    @PostMapping("/track-like/{username}")
    void trackLikeProgressForUser(@PathVariable String username);

    @PostMapping("/track-support/{username}")
    void trackSupportProgressForUser(@PathVariable String username);
}
