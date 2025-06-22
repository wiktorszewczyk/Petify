package org.petify.feed.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.feed.dto.EventRequest;
import org.petify.feed.dto.EventResponse;
import org.petify.feed.exception.FeedItemNotFoundException;
import org.petify.feed.mapper.EventMapper;
import org.petify.feed.model.Event;
import org.petify.feed.repository.EventRepository;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EventServiceTest {

    @Mock
    private EventRepository eventRepository;

    @Mock
    private EventMapper eventMapper;

    @InjectMocks
    private EventService eventService;

    @Test
    void getEventById_WhenExists_ShouldReturnEvent() {
        // Arrange
        Long eventId = 1L;
        Event event = new Event();
        EventResponse response = new EventResponse(eventId, 1L, "Test", "Desc", 
            LocalDateTime.now(), LocalDateTime.now().plusHours(2), "Address", 
            null, null, null, null, null, null, LocalDateTime.now(), LocalDateTime.now());
        
        when(eventRepository.findById(eventId)).thenReturn(Optional.of(event));
        when(eventMapper.toDto(event)).thenReturn(response);

        // Act
        EventResponse result = eventService.getEventById(eventId);

        // Assert
        assertEquals(response, result);
    }

    @Test
    void getEventById_WhenNotExists_ShouldThrowException() {
        // Arrange
        Long eventId = 1L;
        
        when(eventRepository.findById(eventId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThrows(FeedItemNotFoundException.class, () -> 
            eventService.getEventById(eventId));
    }

    @Test
    void createEvent_ShouldSaveAndReturnEvent() {
        // Arrange
        Long shelterId = 1L;
        EventRequest request = new EventRequest("Test", "Desc", 
            LocalDateTime.now(), LocalDateTime.now().plusHours(2), "Address", 
            null, null, null, null, null, null);
        Event event = new Event();
        EventResponse response = new EventResponse(1L, shelterId, "Test", "Desc", 
            request.startDate(), request.endDate(), "Address", 
            null, null, null, null, null, null, LocalDateTime.now(), LocalDateTime.now());
        
        when(eventMapper.toEntity(request)).thenReturn(event);
        when(eventRepository.save(event)).thenReturn(event);
        when(eventMapper.toDto(event)).thenReturn(response);

        // Act
        EventResponse result = eventService.createEvent(shelterId, request);

        // Assert
        assertEquals(response, result);
        assertEquals(shelterId, event.getShelterId());
    }

    @Test
    void updateEvent_WhenExists_ShouldUpdateAndReturnEvent() {
        // Arrange
        Long eventId = 1L;
        EventRequest request = new EventRequest("Updated", "New Desc", 
            LocalDateTime.now(), LocalDateTime.now().plusHours(3), "New Address", 
            null, null, null, 1.0, 2.0, 10);
        Event existingEvent = new Event();
        EventResponse response = new EventResponse(eventId, 1L, "Updated", "New Desc", 
            request.startDate(), request.endDate(), "New Address", 
            null, null, null, 1.0, 2.0, 10, LocalDateTime.now(), LocalDateTime.now());
        
        when(eventRepository.findById(eventId)).thenReturn(Optional.of(existingEvent));
        when(eventRepository.save(existingEvent)).thenReturn(existingEvent);
        when(eventMapper.toDto(existingEvent)).thenReturn(response);

        // Act
        EventResponse result = eventService.updateEvent(eventId, request);

        // Assert
        assertEquals(response, result);
        assertEquals("Updated", existingEvent.getTitle());
        assertEquals("New Desc", existingEvent.getShortDescription());
    }

    @Test
    void deleteEvent_WhenExists_ShouldDelete() {
        // Arrange
        Long eventId = 1L;
        
        when(eventRepository.existsById(eventId)).thenReturn(true);

        // Act
        eventService.deleteEvent(eventId);

        // Assert
        verify(eventRepository).deleteById(eventId);
    }
}
