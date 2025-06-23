package org.petify.reservations.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.reservations.client.PetClient;
import org.petify.reservations.dto.SlotBatchRequest;
import org.petify.reservations.dto.SlotRequest;
import org.petify.reservations.dto.SlotResponse;
import org.petify.reservations.dto.TimeWindowRequest;
import org.petify.reservations.exception.*;
import org.petify.reservations.model.ReservationSlot;
import org.petify.reservations.model.ReservationStatus;
import org.petify.reservations.repository.SlotRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ReservationServiceTest {

    @Mock
    private SlotRepository slotRepository;

    @Mock
    private PetClient petClient;

    @InjectMocks
    private ReservationService reservationService;

    private ReservationSlot testSlot;
    private SlotRequest testSlotRequest;
    private SlotBatchRequest testBatchRequest;

    @BeforeEach
    void setUp() {
        LocalDateTime startTime = LocalDateTime.now().plusDays(1);
        LocalDateTime endTime = startTime.plusHours(2);

        testSlot = new ReservationSlot();
        testSlot.setId(1L);
        testSlot.setPetId(1L);
        testSlot.setStartTime(startTime);
        testSlot.setEndTime(endTime);
        testSlot.setStatus(ReservationStatus.AVAILABLE);
        testSlot.setReservedBy(null);

        testSlotRequest = new SlotRequest(1L, startTime, endTime);

        testBatchRequest = new SlotBatchRequest(
                List.of(1L, 2L),
                false,
                LocalDate.now().plusDays(1),
                LocalDate.now().plusDays(2),
                List.of(new TimeWindowRequest(LocalTime.of(10, 0), LocalTime.of(12, 0)))
        );
    }

    @Test
    void createSlot_ShouldCreateSuccessfully() {
        // given
        when(petClient.getAllPetIds()).thenReturn(List.of(1L, 2L, 3L));
        when(petClient.isPetArchived(1L)).thenReturn(false);
        when(slotRepository.existsByPetIdAndStartTimeAndEndTime(anyLong(), any(), any())).thenReturn(false);
        when(slotRepository.save(any(ReservationSlot.class))).thenReturn(testSlot);

        // when
        SlotResponse result = reservationService.createSlot(testSlotRequest);

        // then
        assertThat(result.id()).isEqualTo(1L);
        assertThat(result.petId()).isEqualTo(1L);
        assertThat(result.status()).isEqualTo(ReservationStatus.AVAILABLE);
        verify(slotRepository).save(any(ReservationSlot.class));
    }

    @Test
    void createSlot_ShouldThrowWhenSlotAlreadyExists() {
        // given
        when(petClient.getAllPetIds()).thenReturn(List.of(1L, 2L, 3L));
        when(petClient.isPetArchived(1L)).thenReturn(false);
        when(slotRepository.existsByPetIdAndStartTimeAndEndTime(anyLong(), any(), any())).thenReturn(true);

        // when & then
        assertThatThrownBy(() -> reservationService.createSlot(testSlotRequest))
                .isInstanceOf(SlotAlreadyExistsException.class);
    }

    @Test
    void createSlot_ShouldThrowWhenStartTimeAfterEndTime() {
        // given
        SlotRequest invalidRequest = new SlotRequest(
                1L,
                LocalDateTime.now().plusDays(1),
                LocalDateTime.now().plusDays(1).minusHours(1)
        );

        // when & then
        assertThatThrownBy(() -> reservationService.createSlot(invalidRequest))
                .isInstanceOf(InvalidTimeRangeException.class)
                .hasMessageContaining("Start time must be before end time");
    }

    @Test
    void createSlot_ShouldThrowWhenStartTimeInPast() {
        // given
        SlotRequest pastRequest = new SlotRequest(
                1L,
                LocalDateTime.now().minusHours(1),
                LocalDateTime.now().plusHours(1)
        );

        // when & then
        assertThatThrownBy(() -> reservationService.createSlot(pastRequest))
                .isInstanceOf(InvalidTimeRangeException.class)
                .hasMessageContaining("Start time cannot be in the past");
    }

    @Test
    void reserveSlot_ShouldReserveSuccessfully() {
        // given
        when(slotRepository.findById(1L)).thenReturn(Optional.of(testSlot));
        when(petClient.isPetArchived(1L)).thenReturn(false);

        ReservationSlot reservedSlot = new ReservationSlot();
        reservedSlot.setId(1L);
        reservedSlot.setPetId(1L);
        reservedSlot.setStartTime(testSlot.getStartTime());
        reservedSlot.setEndTime(testSlot.getEndTime());
        reservedSlot.setStatus(ReservationStatus.RESERVED);
        reservedSlot.setReservedBy("testuser");

        when(slotRepository.save(any(ReservationSlot.class))).thenReturn(reservedSlot);

        // when
        SlotResponse result = reservationService.reserveSlot(1L, "testuser");

        // then
        assertThat(result.status()).isEqualTo(ReservationStatus.RESERVED);
        assertThat(result.reservedBy()).isEqualTo("testuser");
        verify(slotRepository).save(any(ReservationSlot.class));
    }

    @Test
    void reserveSlot_ShouldThrowWhenSlotNotFound() {
        // given
        when(slotRepository.findById(1L)).thenReturn(Optional.empty());

        // when & then
        assertThatThrownBy(() -> reservationService.reserveSlot(1L, "testuser"))
                .isInstanceOf(SlotNotFoundException.class);
    }

    @Test
    void reserveSlot_ShouldThrowWhenSlotNotAvailable() {
        // given
        testSlot.setStatus(ReservationStatus.RESERVED);
        when(slotRepository.findById(1L)).thenReturn(Optional.of(testSlot));
        when(petClient.isPetArchived(1L)).thenReturn(false);

        // when & then
        assertThatThrownBy(() -> reservationService.reserveSlot(1L, "testuser"))
                .isInstanceOf(SlotNotAvailableException.class);
    }

    @Test
    void cancelReservation_ShouldCancelSuccessfully() {
        // given
        testSlot.setStatus(ReservationStatus.RESERVED);
        testSlot.setReservedBy("testuser");
        when(slotRepository.findById(1L)).thenReturn(Optional.of(testSlot));
        when(petClient.getOwnerByPetId(1L)).thenReturn("shelterowner");

        ReservationSlot cancelledSlot = new ReservationSlot();
        cancelledSlot.setId(1L);
        cancelledSlot.setPetId(1L);
        cancelledSlot.setStartTime(testSlot.getStartTime());
        cancelledSlot.setEndTime(testSlot.getEndTime());
        cancelledSlot.setStatus(ReservationStatus.CANCELLED);
        cancelledSlot.setReservedBy("testuser");

        when(slotRepository.save(any(ReservationSlot.class))).thenReturn(cancelledSlot);

        // when
        SlotResponse result = reservationService.cancelReservation(1L, "testuser", List.of("ROLE_USER"));

        // then
        assertThat(result.status()).isEqualTo(ReservationStatus.CANCELLED);
        verify(slotRepository).save(any(ReservationSlot.class));
    }

    @Test
    void cancelReservation_ShouldThrowWhenUnauthorized() {
        // given
        testSlot.setStatus(ReservationStatus.RESERVED);
        testSlot.setReservedBy("otheruser");
        when(slotRepository.findById(1L)).thenReturn(Optional.of(testSlot));
        when(petClient.getOwnerByPetId(1L)).thenReturn("shelterowner");

        // when & then
        assertThatThrownBy(() -> reservationService.cancelReservation(1L, "testuser", List.of("ROLE_USER")))
                .isInstanceOf(UnauthorizedOperationException.class);
    }

    @Test
    void cancelReservation_ShouldThrowWhenSlotNotReserved() {
        // given
        testSlot.setStatus(ReservationStatus.AVAILABLE);
        when(slotRepository.findById(1L)).thenReturn(Optional.of(testSlot));
        when(petClient.getOwnerByPetId(1L)).thenReturn("testuser");

        // when & then
        assertThatThrownBy(() -> reservationService.cancelReservation(1L, "testuser", List.of("ROLE_USER")))
                .isInstanceOf(SlotNotAvailableException.class)
                .hasMessageContaining("Slot is not currently reserved");
    }

    @Test
    void deleteSlot_ShouldDeleteSuccessfully() {
        // given
        when(slotRepository.existsById(1L)).thenReturn(true);

        // when
        reservationService.deleteSlot(1L);

        // then
        verify(slotRepository).deleteById(1L);
    }

    @Test
    void deleteSlot_ShouldThrowWhenNotFound() {
        // given
        when(slotRepository.existsById(1L)).thenReturn(false);

        // when & then
        assertThatThrownBy(() -> reservationService.deleteSlot(1L))
                .isInstanceOf(SlotNotFoundException.class);
    }

    @Test
    void getSlotsByPetId_ShouldReturnSlots() {
        // given
        when(petClient.isPetArchived(1L)).thenReturn(false);
        when(slotRepository.findByPetId(1L)).thenReturn(List.of(testSlot));

        // when
        List<SlotResponse> result = reservationService.getSlotsByPetId(1L);

        // then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).petId()).isEqualTo(1L);
    }

    @Test
    void getSlotsByPetId_ShouldReturnEmptyWhenPetArchived() {
        // given
        when(petClient.isPetArchived(1L)).thenReturn(true);

        // when
        List<SlotResponse> result = reservationService.getSlotsByPetId(1L);

        // then
        assertThat(result).isEmpty();
        verify(slotRepository, never()).findByPetId(anyLong());
    }

    @Test
    void getSlotsByUser_ShouldReturnUserSlots() {
        // given
        testSlot.setReservedBy("testuser");
        when(slotRepository.findByReservedBy("testuser")).thenReturn(List.of(testSlot));

        // when
        List<SlotResponse> result = reservationService.getSlotsByUser("testuser");

        // then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).reservedBy()).isEqualTo("testuser");
    }

    @Test
    void createBatchSlots_ShouldCreateMultipleSlots() {
        // given
        when(petClient.getAllPetIds()).thenReturn(List.of(1L, 2L));
        when(petClient.isPetArchived(anyLong())).thenReturn(false);
        when(slotRepository.existsByPetIdAndStartTimeAndEndTime(anyLong(), any(), any())).thenReturn(false);
        when(slotRepository.saveAll(any())).thenReturn(List.of(testSlot));

        // when
        List<SlotResponse> result = reservationService.createBatchSlots(testBatchRequest);

        // then
        assertThat(result).isNotEmpty();
        verify(slotRepository).saveAll(any());
    }

    @Test
    void createBatchSlots_ShouldThrowWhenNoPetIds() {
        // given
        SlotBatchRequest emptyRequest = new SlotBatchRequest(
                List.of(),
                false,
                LocalDate.now().plusDays(1),
                LocalDate.now().plusDays(2),
                List.of(new TimeWindowRequest(LocalTime.of(10, 0), LocalTime.of(12, 0)))
        );

        // when & then
        assertThatThrownBy(() -> reservationService.createBatchSlots(emptyRequest))
                .isInstanceOf(InvalidTimeRangeException.class);
    }

    @Test
    void createBatchSlots_ShouldThrowWhenStartDateAfterEndDate() {
        // given
        SlotBatchRequest invalidRequest = new SlotBatchRequest(
                List.of(1L),
                false,
                LocalDate.now().plusDays(2),
                LocalDate.now().plusDays(1),
                List.of(new TimeWindowRequest(LocalTime.of(10, 0), LocalTime.of(12, 0)))
        );

        // when & then
        assertThatThrownBy(() -> reservationService.createBatchSlots(invalidRequest))
                .isInstanceOf(InvalidTimeRangeException.class);
    }

    @Test
    void getAllSlots_ShouldReturnAllNonArchivedSlots() {
        // given
        when(slotRepository.findAll()).thenReturn(List.of(testSlot));
        when(petClient.isPetArchived(1L)).thenReturn(false);

        // when
        List<SlotResponse> result = reservationService.getAllSlots();

        // then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).id()).isEqualTo(1L);
    }

    @Test
    void getAvailableSlots_ShouldReturnOnlyAvailableSlots() {
        // given
        ReservationSlot reservedSlot = new ReservationSlot();
        reservedSlot.setId(2L);
        reservedSlot.setPetId(2L);
        reservedSlot.setStartTime(LocalDateTime.now().plusDays(1));
        reservedSlot.setEndTime(LocalDateTime.now().plusDays(1).plusHours(2));
        reservedSlot.setStatus(ReservationStatus.RESERVED);
        reservedSlot.setReservedBy("user");

        when(slotRepository.findAll()).thenReturn(List.of(testSlot, reservedSlot));
        when(petClient.isPetArchived(anyLong())).thenReturn(false);

        // when
        List<SlotResponse> result = reservationService.getAvailableSlots();

        // then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).status()).isEqualTo(ReservationStatus.AVAILABLE);
    }

    @Test
    void reactivateCancelledSlot_ShouldReactivateSuccessfully() {
        // given
        testSlot.setStatus(ReservationStatus.CANCELLED);
        when(slotRepository.findById(1L)).thenReturn(Optional.of(testSlot));

        ReservationSlot reactivatedSlot = new ReservationSlot();
        reactivatedSlot.setId(1L);
        reactivatedSlot.setPetId(1L);
        reactivatedSlot.setStartTime(testSlot.getStartTime());
        reactivatedSlot.setEndTime(testSlot.getEndTime());
        reactivatedSlot.setStatus(ReservationStatus.AVAILABLE);
        reactivatedSlot.setReservedBy(null);

        when(slotRepository.save(any(ReservationSlot.class))).thenReturn(reactivatedSlot);

        // when
        SlotResponse result = reservationService.reactivateCancelledSlot(1L, List.of("ROLE_ADMIN"));

        // then
        assertThat(result.status()).isEqualTo(ReservationStatus.AVAILABLE);
        assertThat(result.reservedBy()).isNull();
        verify(slotRepository).save(any(ReservationSlot.class));
    }

    @Test
    void reactivateCancelledSlot_ShouldThrowWhenNotCancelled() {
        // given
        testSlot.setStatus(ReservationStatus.AVAILABLE);
        when(slotRepository.findById(1L)).thenReturn(Optional.of(testSlot));

        // when & then
        assertThatThrownBy(() -> reservationService.reactivateCancelledSlot(1L, List.of("ROLE_ADMIN")))
                .isInstanceOf(SlotNotAvailableException.class)
                .hasMessageContaining("Slot is not currently cancelled");
    }
}
