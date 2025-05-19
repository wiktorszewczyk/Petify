package org.petify.backend.repository;

import java.util.List;
import java.util.Optional;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.VolunteerStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserRepository extends JpaRepository<ApplicationUser, Integer> {
    Optional<ApplicationUser> findByUsername(String username);

    Optional<ApplicationUser> findByEmail(String email);

    Optional<ApplicationUser> findByPhoneNumber(String phoneNumber);

    Optional<ApplicationUser> findByEmailOrPhoneNumber(String email, String phoneNumber);

    List<ApplicationUser> findByVolunteerStatus(VolunteerStatus status);

    List<ApplicationUser> findByVolunteerStatusNot(VolunteerStatus status);

    List<ApplicationUser> findByActiveIsFalse();
}
