package org.petify.reservations.service;

import lombok.RequiredArgsConstructor;
import org.petify.reservations.dto.SlotRequest;
import org.petify.reservations.dto.SlotResponse;
import org.petify.reservations.model.ReservationSlot;
import org.petify.reservations.model.ReservationStatus;
import org.petify.reservations.repository.SlotRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class ReservationService {

    private final SlotRepository repo;

    /* ==========  CRUD – ADMIN  ========== */

    public SlotResponse createSlot(SlotRequest r) {
        ReservationSlot slot = new ReservationSlot(
                null,
                r.petId(),
                r.startTime(),
                r.endTime(),
                ReservationStatus.AVAILABLE,   // nowy slot jest wolny
                null
        );
        return mapToResponse(repo.save(slot));
    }

    public void deleteSlot(Long slotId) {
        repo.deleteById(slotId);
    }

    /* ==========  REZERWACJE – USER / ADMIN  ========== */

    public SlotResponse reserveSlot(Long slotId, String username) {
        ReservationSlot slot = repo.findById(slotId)
                .orElseThrow(() -> new IllegalArgumentException("Slot not found"));

        if (slot.getStatus() != ReservationStatus.AVAILABLE) {
            throw new IllegalStateException("Slot is not available");
        }
        slot.setReservedBy(username);
        slot.setStatus(ReservationStatus.RESERVED);

        return mapToResponse(repo.save(slot));
    }

    /**
     * @param admin true – operacja wywołana przez ADMINA, false – przez USER-a
     */
    public SlotResponse cancelReservation(Long slotId, String username, boolean admin) {
        ReservationSlot slot = repo.findById(slotId)
                .orElseThrow(() -> new IllegalArgumentException("Slot not found"));

        // USER może odwołać tylko swoją rezerwację
        if (!admin && !username.equals(slot.getReservedBy())) {
            throw new IllegalStateException("You are not allowed to cancel this reservation");
        }
        slot.setReservedBy(null);
        slot.setStatus(ReservationStatus.AVAILABLE);

        return mapToResponse(repo.save(slot));
    }

    /* ==========  LISTING  ========== */

    public List<SlotResponse> getSlotsByPetId(Long petId) {
        return repo.findByPetId(petId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public List<SlotResponse> getSlotsByUser(String username) {
        return repo.findByReservedBy(username)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    /* ==========  MAPPER  ========== */

    private SlotResponse mapToResponse(ReservationSlot slot) {
        return new SlotResponse(
                slot.getId(),
                slot.getPetId(),
                slot.getStartTime(),
                slot.getEndTime(),
                slot.getStatus(),
                slot.getReservedBy()
        );
    }
}
