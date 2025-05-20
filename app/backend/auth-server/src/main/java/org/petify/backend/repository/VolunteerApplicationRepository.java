package org.petify.backend.repository;

import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.VolunteerApplication;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VolunteerApplicationRepository extends JpaRepository<VolunteerApplication, Long> {
    List<VolunteerApplication> findByUserOrderByApplicationDateDesc(ApplicationUser user);

    List<VolunteerApplication> findByStatus(String status);
}
