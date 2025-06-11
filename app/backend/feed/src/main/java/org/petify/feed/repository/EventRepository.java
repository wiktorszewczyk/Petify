package org.petify.feed.repository;

import org.petify.feed.model.Event;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface EventRepository extends JpaRepository<Event, Long>, JpaSpecificationExecutor<Event> {
    @Query("SELECT e FROM Event e "
            + "JOIN FeedItem f ON e.id = f.id "
            + "WHERE e.startDate <= :tillDate AND e.endDate >= :now "
            + "ORDER BY e.startDate ASC")
    List<Event> findAllIncomingEvents(@Param("tillDate") LocalDateTime tillDate, @Param("now") LocalDateTime now);

    List<Event> findAllByShelterId(Long shelterId);
}
