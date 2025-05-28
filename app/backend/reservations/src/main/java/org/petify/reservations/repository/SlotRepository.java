package org.petify.reservations.repository;

import org.petify.reservations.model.ReservationSlot;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface SlotRepository extends JpaRepository<ReservationSlot, Long> {
    boolean existsByPetIdAndStartTimeAndEndTime(Long petId,
                                                LocalDateTime start,
                                                LocalDateTime end);

    List<ReservationSlot> findByPetId(Long petId);

    List<ReservationSlot> findByReservedBy(String username);
}
