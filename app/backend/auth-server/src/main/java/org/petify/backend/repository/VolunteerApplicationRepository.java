package org.petify.backend.repository;

import java.util.List;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.VolunteerApplication;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VolunteerApplicationRepository extends JpaRepository<VolunteerApplication, Long> {
    List<VolunteerApplication> findByUserOrderByApplicationDateDesc(ApplicationUser user);

    List<VolunteerApplication> findByStatus(String status);
}
