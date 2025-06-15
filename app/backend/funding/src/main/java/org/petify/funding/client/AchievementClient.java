package org.petify.funding.client;

import org.petify.funding.config.FeignJwtConfiguration;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@FeignClient(
        name = "auth-service",
        path = "/user/achievements",
        configuration = FeignJwtConfiguration.class
)
public interface AchievementClient {

    @PostMapping("/track-support")
    void trackSupportProgress();

    @PostMapping("/track-like")
    void trackLikeProgress();

    @PostMapping("/add-donation-xp")
    void addDonationExperiencePoints(@RequestParam("xpPoints") int xpPoints);
}
