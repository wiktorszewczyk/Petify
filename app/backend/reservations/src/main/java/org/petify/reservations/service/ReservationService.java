package org.petify.reservations.service;

import org.petify.reservations.client.PetClient;
import org.petify.reservations.dto.SlotBatchRequest;
import org.petify.reservations.dto.SlotRequest;
import org.petify.reservations.dto.SlotResponse;
import org.petify.reservations.dto.TimeWindowRequest;
import org.petify.reservations.exception.InvalidTimeRangeException;
import org.petify.reservations.exception.PetNotFoundException;
import org.petify.reservations.exception.PetServiceUnavailableException;
import org.petify.reservations.exception.SlotAlreadyExistsException;
import org.petify.reservations.exception.SlotNotAvailableException;
import org.petify.reservations.exception.SlotNotFoundException;
import org.petify.reservations.exception.UnauthorizedOperationException;
import org.petify.reservations.model.ReservationSlot;
import org.petify.reservations.model.ReservationStatus;
import org.petify.reservations.repository.SlotRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
        validatePetExistence(r.petId());
        validatePetNotArchived(r.petId());

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

        validatePetNotArchived(slot.getPetId());

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
                .filter(slot -> {
                    try {
                        return !petClient.isPetArchived(slot.getPetId());
                    } catch (Exception e) {
                        log.warn("Could not check archive status for pet {}. Including slot.", slot.getPetId());
                        return true;
                    }
                })
                .map(this::mapToResponse)
                .toList();
    }

    public List<SlotResponse> getAvailableSlots() {
        return repo.findAll()
                .stream()
                .filter(slot -> slot.getStatus() == ReservationStatus.AVAILABLE)
                .filter(slot -> {
                    try {
                        return !petClient.isPetArchived(slot.getPetId());
                    } catch (Exception e) {
                        log.warn("Could not check archive status for pet {}. Including slot.", slot.getPetId());
                        return true;
                    }
                })
                .map(this::mapToResponse)
                .toList();
    }

    public SlotResponse cancelReservation(Long slotId, String username, List<String> roles) {
        validateSlotId(slotId);
        validateUsername(username);

        ReservationSlot slot = repo.findById(slotId)
                .orElseThrow(() -> new SlotNotFoundException("Slot with ID " + slotId + " not found"));

        boolean isReservationOwner = username.equals(slot.getReservedBy());

        boolean isAdmin = roles != null && roles.stream()
                .anyMatch(r -> r.contains("ADMIN"));

        boolean isShelterOwnerOfPet = false;
        try {
            String shelterOwnerUsername = petClient.getOwnerByPetId(slot.getPetId());
            isShelterOwnerOfPet = username.equals(shelterOwnerUsername);
        } catch (Exception e) {
            log.error("Could not verify pet ownership for petId {}. Error: {}", slot.getPetId(), e.getMessage());
        }

        if (!isReservationOwner && !isAdmin && !isShelterOwnerOfPet) {
            throw new UnauthorizedOperationException("You are not authorized to cancel this reservation");
        }

        if (slot.getStatus() != ReservationStatus.RESERVED) {
            throw new SlotNotAvailableException("Slot is not currently reserved");
        }

        slot.setStatus(ReservationStatus.CANCELLED);

        log.info("Reservation for slot {} cancelled by {}", slotId, username);
        return mapToResponse(repo.save(slot));
    }

    public List<SlotResponse> getSlotsByPetId(Long petId) {
        validatePetId(petId);

        try {
            boolean isArchived = petClient.isPetArchived(petId);
            if (isArchived) {
                return List.of();
            }
        } catch (Exception e) {
            log.warn("Could not check archive status for pet {}. Returning slots anyway.", petId);
        }

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
            if (r.allPets()) {
                try {
                    Long shelterId = petClient.getMyShelterIdAndVerifyOwnership();
                    targetPetIds = petClient.getPetIdsByShelterId(shelterId);
                } catch (Exception e) {
                    targetPetIds = petClient.getAllPetIds();
                }
            } else {
                targetPetIds = r.petIds();
            }

            targetPetIds = filterArchivedPets(targetPetIds);

        } catch (Exception e) {
            log.error("Failed to fetch pet IDs from pet service", e);
            throw new PetServiceUnavailableException("Unable to fetch pet information. Please try again later.");
        }

        if (CollectionUtils.isEmpty(targetPetIds)) {
            throw new InvalidTimeRangeException("No valid pet IDs found for slot creation");
        }

        if (!r.allPets()) {
            List<Long> existingPetIds = petClient.getAllPetIds();
            for (Long petId : r.petIds()) {
                if (!existingPetIds.contains(petId)) {
                    throw new PetNotFoundException("Pet with ID " + petId + " not found");
                }
            }
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

    public SlotResponse reactivateCancelledSlot(Long slotId, List<String> roles) {
        validateSlotId(slotId);

        ReservationSlot slot = repo.findById(slotId)
                .orElseThrow(() -> new SlotNotFoundException("Slot with ID " + slotId + " not found"));

        if (slot.getStatus() != ReservationStatus.CANCELLED) {
            throw new SlotNotAvailableException("Slot is not currently cancelled");
        }

        slot.setStatus(ReservationStatus.AVAILABLE);
        slot.setReservedBy(null);
        return mapToResponse(repo.save(slot));
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

    private void validatePetExistence(Long petId) {
        List<Long> existingPetIds = petClient.getAllPetIds();
        if (!existingPetIds.contains(petId)) {
            throw new PetNotFoundException("Pet with ID " + petId + " not found");
        }
    }

    private void validateUsername(String username) {
        if (username == null || username.trim().isEmpty()) {
            throw new IllegalArgumentException("Username cannot be null or empty");
        }
    }

    private void validatePetNotArchived(Long petId) {
        try {
            boolean isArchived = petClient.isPetArchived(petId);
            if (isArchived) {
                throw new IllegalArgumentException("Cannot create slots for archived pet with ID " + petId);
            }
        } catch (Exception e) {
            log.error("Could not verify pet archive status for petId {}. Error: {}", petId, e.getMessage());
            throw new PetServiceUnavailableException("Unable to verify pet status");
        }
    }

    private List<Long> filterArchivedPets(List<Long> petIds) {
        List<Long> activePetIds = new ArrayList<>();

        for (Long petId : petIds) {
            try {
                boolean isArchived = petClient.isPetArchived(petId);
                if (!isArchived) {
                    activePetIds.add(petId);
                } else {
                    log.info("Skipping archived pet with ID {}", petId);
                }
            } catch (Exception e) {
                log.warn("Could not check archive status for pet {}. Skipping. Error: {}", petId, e.getMessage());
            }
        }

        log.info("Filtered {} active pets from {} total pets", activePetIds.size(), petIds.size());
        return activePetIds;
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
