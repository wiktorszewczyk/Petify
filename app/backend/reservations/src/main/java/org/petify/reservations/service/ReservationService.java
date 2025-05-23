package org.petify.reservations.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.petify.reservations.client.PetClient;
import org.petify.reservations.dto.SlotBatchRequest;
import org.petify.reservations.dto.SlotRequest;
import org.petify.reservations.dto.SlotResponse;
import org.petify.reservations.dto.TimeWindowRequest;
import org.petify.reservations.exception.*;
import org.petify.reservations.model.ReservationSlot;
import org.petify.reservations.model.ReservationStatus;
import org.petify.reservations.repository.SlotRepository;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.CollectionUtils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class ReservationService {

    private final SlotRepository repo;
    private final PetClient petClient;

    public SlotResponse createSlot(SlotRequest r) {
        validateSlotRequest(r);

        if (repo.existsByPetIdAndStartTimeAndEndTime(r.petId(), r.startTime(), r.endTime())) {
            throw new SlotAlreadyExistsException(
                    String.format("Slot already exists for pet %d at %s - %s",
                            r.petId(), r.startTime(), r.endTime()));
        }

        ReservationSlot slot = new ReservationSlot(
                null,
                r.petId(),
                r.startTime(),
                r.endTime(),
                ReservationStatus.AVAILABLE,
                null
        );

        log.info("Creating new slot for pet {} from {} to {}", r.petId(), r.startTime(), r.endTime());
        return mapToResponse(repo.save(slot));
    }

    public void deleteSlot(Long slotId) {
        validateSlotId(slotId);

        if (!repo.existsById(slotId)) {
            throw new SlotNotFoundException("Slot with ID " + slotId + " not found");
        }

        log.info("Deleting slot with ID {}", slotId);
        repo.deleteById(slotId);
    }

    public void deleteAllSlots() {
        long count = repo.count();
        repo.deleteAll();
        log.info("Deleted {} slots", count);
    }

    public SlotResponse reserveSlot(Long slotId, String username) {
        validateSlotId(slotId);
        validateUsername(username);

        ReservationSlot slot = repo.findById(slotId)
                .orElseThrow(() -> new SlotNotFoundException("Slot with ID " + slotId + " not found"));

        if (slot.getStatus() != ReservationStatus.AVAILABLE) {
            throw new SlotNotAvailableException("Slot is not available for reservation");
        }

        slot.setReservedBy(username);
        slot.setStatus(ReservationStatus.RESERVED);

        log.info("User {} reserved slot {}", username, slotId);
        return mapToResponse(repo.save(slot));
    }

    public List<SlotResponse> getAllSlots() {
        return repo.findAll()
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public List<SlotResponse> getAvailableSlots() {
        return repo.findAll()
                .stream()
                .filter(slot -> slot.getStatus() == ReservationStatus.AVAILABLE)
                .map(this::mapToResponse)
                .toList();
    }

    public SlotResponse cancelReservation(Long slotId, String username) {
        validateSlotId(slotId);
        validateUsername(username);

        ReservationSlot slot = repo.findById(slotId)
                .orElseThrow(() -> new SlotNotFoundException("Slot with ID " + slotId + " not found"));

        // Check if user has permission to cancel the reservation
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        boolean isAdminOrShelter = auth.getAuthorities().stream()
                .anyMatch(grantedAuthority ->
                        grantedAuthority.getAuthority().equals("ROLE_ADMIN") ||
                                grantedAuthority.getAuthority().equals("ROLE_SHELTER"));

        boolean isOwner = username.equals(slot.getReservedBy());

        if (!isAdminOrShelter && !isOwner) {
            throw new UnauthorizedOperationException("You are not authorized to cancel this reservation");
        }

        if (slot.getStatus() != ReservationStatus.RESERVED) {
            throw new SlotNotAvailableException("Slot is not currently reserved");
        }

        slot.setReservedBy(null);
        slot.setStatus(ReservationStatus.AVAILABLE);

        log.info("Reservation for slot {} cancelled by {}", slotId, username);
        return mapToResponse(repo.save(slot));
    }

    public List<SlotResponse> getSlotsByPetId(Long petId) {
        validatePetId(petId);

        return repo.findByPetId(petId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public List<SlotResponse> getSlotsByUser(String username) {
        validateUsername(username);

        return repo.findByReservedBy(username)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public List<SlotResponse> createBatchSlots(SlotBatchRequest r) {
        validateBatchRequest(r);

        List<Long> targetPetIds;
        try {
            targetPetIds = r.allPets() ? petClient.getAllPetIds() : r.petIds();
        } catch (Exception e) {
            log.error("Failed to fetch pet IDs from pet service", e);
            throw new PetServiceUnavailableException("Unable to fetch pet information. Please try again later.");
        }

        if (CollectionUtils.isEmpty(targetPetIds)) {
            throw new InvalidTimeRangeException("No valid pet IDs found for slot creation");
        }

        List<ReservationSlot> slotsToSave = new ArrayList<>();
        int skippedCount = 0;

        for (LocalDate d = r.startDate(); !d.isAfter(r.endDate()); d = d.plusDays(1)) {
            for (TimeWindowRequest w : r.timeWindows()) {
                LocalDateTime start = d.atTime(w.start());
                LocalDateTime end = d.atTime(w.end());

                for (Long petId : targetPetIds) {
                    if (repo.existsByPetIdAndStartTimeAndEndTime(petId, start, end)) {
                        skippedCount++;
                        continue;
                    }

                    slotsToSave.add(new ReservationSlot(
                            petId, start, end, ReservationStatus.AVAILABLE, null));
                }
            }
        }

        log.info("Creating {} slots in batch, skipped {} existing slots", slotsToSave.size(), skippedCount);
        return repo.saveAll(slotsToSave).stream()
                .map(this::mapToResponse)
                .toList();
    }

    private void validateSlotRequest(SlotRequest r) {
        if (r.startTime().isAfter(r.endTime()) || r.startTime().isEqual(r.endTime())) {
            throw new InvalidTimeRangeException("Start time must be before end time");
        }

        if (r.startTime().isBefore(LocalDateTime.now())) {
            throw new InvalidTimeRangeException("Start time cannot be in the past");
        }
    }

    private void validateBatchRequest(SlotBatchRequest r) {
        if (r.startDate().isAfter(r.endDate())) {
            throw new InvalidTimeRangeException("Start date must be before or equal to end date");
        }

        if (!r.allPets() && CollectionUtils.isEmpty(r.petIds())) {
            throw new InvalidTimeRangeException("Pet IDs must be provided when allPets is false");
        }

        for (TimeWindowRequest window : r.timeWindows()) {
            if (window.start().isAfter(window.end()) || window.start().equals(window.end())) {
                throw new InvalidTimeRangeException("Time window start must be before end time");
            }
        }
    }

    private void validateSlotId(Long slotId) {
        if (slotId == null || slotId <= 0) {
            throw new IllegalArgumentException("Slot ID must be a positive number");
        }
    }

    private void validatePetId(Long petId) {
        if (petId == null || petId <= 0) {
            throw new IllegalArgumentException("Pet ID must be a positive number");
        }
    }

    private void validateUsername(String username) {
        if (username == null || username.trim().isEmpty()) {
            throw new IllegalArgumentException("Username cannot be null or empty");
        }
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