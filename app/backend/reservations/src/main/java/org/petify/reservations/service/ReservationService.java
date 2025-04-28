package org.petify.reservations.service;

import lombok.RequiredArgsConstructor;
import org.petify.reservations.client.PetClient;
import org.petify.reservations.dto.SlotBatchRequest;
import org.petify.reservations.dto.SlotRequest;
import org.petify.reservations.dto.SlotResponse;
import org.petify.reservations.dto.TimeWindowRequest;
import org.petify.reservations.model.ReservationSlot;
import org.petify.reservations.model.ReservationStatus;
import org.petify.reservations.repository.SlotRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@Transactional
@RequiredArgsConstructor
public class ReservationService {

    private final SlotRepository repo;
    private final PetClient petClient;

    public SlotResponse createSlot(SlotRequest r) {
        ReservationSlot slot = new ReservationSlot(
                null,
                r.petId(),
                r.startTime(),
                r.endTime(),
                ReservationStatus.AVAILABLE,
                null
        );
        return mapToResponse(repo.save(slot));
    }

    public void deleteSlot(Long slotId) {
        repo.deleteById(slotId);
    }

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

        if (!admin && !username.equals(slot.getReservedBy())) {
            throw new IllegalStateException("You are not allowed to cancel this reservation");
        }
        slot.setReservedBy(null);
        slot.setStatus(ReservationStatus.AVAILABLE);

        return mapToResponse(repo.save(slot));
    }

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

    public List<SlotResponse> createBatchSlots(SlotBatchRequest r) {

        List<Long> targetPetIds = r.allPets()
                ? petClient.getAllPetIds()
                : r.petIds();

        List<ReservationSlot> slotsToSave = new ArrayList<>();
        for (LocalDate d = r.startDate(); !d.isAfter(r.endDate()); d = d.plusDays(1)) {
            for (TimeWindowRequest w : r.timeWindows()) {
                LocalDateTime start = d.atTime(w.start());
                LocalDateTime end   = d.atTime(w.end());

                for (Long petId : targetPetIds) {
                    if (repo.existsByPetIdAndStartTimeAndEndTime(petId, start, end)) continue;

                    slotsToSave.add(new ReservationSlot(
                            petId, start, end, ReservationStatus.AVAILABLE, null));
                }
            }
        }
        return repo.saveAll(slotsToSave).stream()
                .map(this::mapToResponse)
                .toList();
    }
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
