package org.petify.feed.repository;

import org.petify.feed.model.EventParticipant;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EventParticipantRepository extends JpaRepository<EventParticipant, Long>, JpaSpecificationExecutor<EventParticipant> {
    List<EventParticipant> findAllByEventId(Long eventId);

    List<EventParticipant> findAllByUsername(String username);

    Optional<EventParticipant> findByEventIdAndUsername(Long eventId, String username);

    int countByEventId(Long eventId);
}
