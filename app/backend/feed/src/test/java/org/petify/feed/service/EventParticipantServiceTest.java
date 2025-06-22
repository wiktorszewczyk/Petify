package org.petify.feed.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.feed.dto.EventParticipantResponse;
import org.petify.feed.exception.AlreadyParticipatingException;
import org.petify.feed.exception.FeedItemNotFoundException;
import org.petify.feed.exception.MaxEventCapacityReachedException;
import org.petify.feed.mapper.EventParticipantMapper;
import org.petify.feed.model.Event;
import org.petify.feed.model.EventParticipant;
import org.petify.feed.repository.EventParticipantRepository;
import org.petify.feed.repository.EventRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EventParticipantServiceTest {

    @Mock
    private EventRepository eventRepository;

    @Mock
    private EventParticipantRepository eventParticipantRepository;

    @Mock
    private EventParticipantMapper eventParticipantMapper;

    @InjectMocks
    private EventParticipantService eventParticipantService;

    @Test
    void getParticipantsByEventId_ShouldReturnParticipants() {
        // Arrange
        Long eventId = 1L;
        EventParticipant participant = new EventParticipant();
        EventParticipantResponse response = new EventParticipantResponse(1L, eventId, "user1", LocalDateTime.now());
        
        when(eventParticipantRepository.findAllByEventId(eventId)).thenReturn(List.of(participant));
        when(eventParticipantMapper.toDto(participant)).thenReturn(response);

        // Act
        List<EventParticipantResponse> result = eventParticipantService.getParticipantsByEventId(eventId);

        // Assert
        assertEquals(1, result.size());
        assertEquals(response, result.get(0));
    }

    @Test
    void addParticipant_WhenNotParticipatingAndCapacityAvailable_ShouldAddParticipant() {
        // Arrange
        Long eventId = 1L;
        String username = "user1";
        Event event = new Event();
        event.setCapacity(10);
        
        when(eventParticipantRepository.findByEventIdAndUsername(eventId, username)).thenReturn(Optional.empty());
        when(eventRepository.findById(eventId)).thenReturn(Optional.of(event));
        when(eventParticipantRepository.countByEventId(eventId)).thenReturn(5);
        when(eventParticipantRepository.save(any(EventParticipant.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(eventParticipantMapper.toDto(any(EventParticipant.class))).thenReturn(new EventParticipantResponse(1L, eventId, username, LocalDateTime.now()));

        // Act
        EventParticipantResponse result = eventParticipantService.addParticipant(eventId, username);

        // Assert
        assertNotNull(result);
        verify(eventParticipantRepository).save(any(EventParticipant.class));
    }

    @Test
    void addParticipant_WhenAlreadyParticipating_ShouldThrowException() {
        // Arrange
        Long eventId = 1L;
        String username = "user1";
        EventParticipant existingParticipant = new EventParticipant();
        
        when(eventParticipantRepository.findByEventIdAndUsername(eventId, username)).thenReturn(Optional.of(existingParticipant));

        // Act & Assert
        assertThrows(AlreadyParticipatingException.class, () -> 
            eventParticipantService.addParticipant(eventId, username));
    }

    @Test
    void addParticipant_WhenCapacityReached_ShouldThrowException() {
        // Arrange
        Long eventId = 1L;
        String username = "user1";
        Event event = new Event();
        event.setCapacity(5);
        
        when(eventParticipantRepository.findByEventIdAndUsername(eventId, username)).thenReturn(Optional.empty());
        when(eventRepository.findById(eventId)).thenReturn(Optional.of(event));
        when(eventParticipantRepository.countByEventId(eventId)).thenReturn(5);

        // Act & Assert
        assertThrows(MaxEventCapacityReachedException.class, () -> 
            eventParticipantService.addParticipant(eventId, username));
    }

    @Test
    void removeParticipant_WhenParticipantExists_ShouldDelete() {
        // Arrange
        Long eventId = 1L;
        String username = "user1";
        EventParticipant participant = new EventParticipant();
        
        when(eventParticipantRepository.findByEventIdAndUsername(eventId, username)).thenReturn(Optional.of(participant));

        // Act
        eventParticipantService.removeParticipant(eventId, username);

        // Assert
        verify(eventParticipantRepository).delete(participant);
    }

    @Test
    void removeParticipant_WhenParticipantNotExists_ShouldThrowException() {
        // Arrange
        Long eventId = 1L;
        String username = "user1";
        
        when(eventParticipantRepository.findByEventIdAndUsername(eventId, username)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(FeedItemNotFoundException.class, () -> 
            eventParticipantService.removeParticipant(eventId, username));
    }
}
