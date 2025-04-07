package org.petify.backend.security.repository;

import java.util.Optional;

import org.petify.backend.security.models.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RoleRepository extends JpaRepository<Role, Integer> {
    Optional<Role> findByAuthority(String authority);
}
