package org.petify.backend.repository;

import java.util.List;
import org.petify.backend.models.Achievement;
import org.petify.backend.models.AchievementCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AchievementRepository extends JpaRepository<Achievement, Long> {
    List<Achievement> findByCategory(AchievementCategory category);
}
