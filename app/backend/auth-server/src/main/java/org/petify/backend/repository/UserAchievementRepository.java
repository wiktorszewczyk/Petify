package org.petify.backend.repository;

import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.UserAchievement;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserAchievementRepository extends JpaRepository<UserAchievement, Long> {
    List<UserAchievement> findByUser(ApplicationUser user);

    List<UserAchievement> findByUserAndCompleted(ApplicationUser user, Boolean completed);

    Optional<UserAchievement> findByUserAndAchievementId(ApplicationUser user, Long achievementId);
}
