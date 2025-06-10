package org.petify.feed.repository;

import org.petify.feed.model.EventParticipant;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface EventParticipantRepository extends JpaRepository<EventParticipant, Long>, JpaSpecificationExecutor<EventParticipant> {
    List<EventParticipant> findByShelterId(Long shelterId);

    List<EventParticipant> findByUsername(String username);
}
