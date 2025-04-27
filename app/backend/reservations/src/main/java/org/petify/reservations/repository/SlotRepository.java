package org.petify.reservations.repository;

import org.petify.reservations.model.ReservationSlot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface SlotRepository extends JpaRepository<ReservationSlot, Long> {
    List<ReservationSlot> findByPetId(Long petId);
    List<ReservationSlot> findByReservedBy(String username);
}
