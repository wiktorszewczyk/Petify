package org.petify.feed.controller;

import org.petify.feed.dto.EventParticipantResponse;
import org.petify.feed.dto.EventRequest;
import org.petify.feed.dto.EventResponse;
import org.petify.feed.service.EventParticipantService;
import org.petify.feed.service.EventService;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.security.oauth2.resource.OAuth2ResourceServerProperties.Jwt;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/events")
public class EventController {
    private final EventService eventService;
    private final EventParticipantService eventParticipantService;

    @GetMapping("/{eventId}")
    public ResponseEntity<EventResponse> getEventById(@PathVariable Long eventId) {
        EventResponse event = eventService.getEventById(eventId);
        return ResponseEntity.ok(event);
    }

    @GetMapping("/shelter/{shelterId}/events")
    public ResponseEntity<List<EventResponse>> getEventsByShelterId(@PathVariable Long shelterId) {
        List<EventResponse> events = eventService.getEventsByShelterId(shelterId);
        return ResponseEntity.ok(events);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @PostMapping("/shelter/{shelterId}/events")
    public ResponseEntity<EventResponse> createEvent(
            @PathVariable Long shelterId,
            @RequestBody EventRequest eventRequest,
            @AuthenticationPrincipal Jwt jwt) {
        if (eventRequest == null) {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        }
        EventResponse event = eventService.createEvent(shelterId, eventRequest);
        return ResponseEntity.status(HttpStatus.CREATED).body(event);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @PutMapping("/{eventId}")
    public ResponseEntity<EventResponse> updateEvent(
            @PathVariable Long eventId,
            @RequestBody EventRequest eventRequest,
            @AuthenticationPrincipal Jwt jwt) {
        if (eventRequest == null) {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        }
        EventResponse updatedEvent = eventService.updateEvent(eventId, eventRequest);
        return ResponseEntity.ok(updatedEvent);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @DeleteMapping("/{eventId}")
    public ResponseEntity<?> deleteEvent(
            @PathVariable Long eventId,
            @AuthenticationPrincipal Jwt jwt) {
        eventService.deleteEvent(eventId);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }

    @GetMapping("/{eventId}/participants")
    public ResponseEntity<List<EventParticipantResponse>> getParticipantsByEventId(@PathVariable Long eventId) {
        List<EventParticipantResponse> participants = eventParticipantService.getParticipantsByEventId(eventId);
        return ResponseEntity.ok(participants);
    }

    @GetMapping("/{username}/events")
    public ResponseEntity<List<EventParticipantResponse>> getEventsByUsername(@PathVariable String username) {
        List<EventParticipantResponse> events = eventParticipantService.getEventsByUsername(username);
        return ResponseEntity.ok(events);
    }

    @GetMapping("/{eventId}/participants/count")
    public ResponseEntity<Integer> countParticipantsByEventId(@PathVariable Long eventId) {
        int count = eventParticipantService.countParticipantsByEventId(eventId);
        return ResponseEntity.ok(count);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @PostMapping("/{eventId}/participants")
    public ResponseEntity<EventParticipantResponse> addParticipant(
            @PathVariable Long eventId,
            @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;
        if (username == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }

        EventParticipantResponse participant = eventParticipantService.addParticipant(eventId, username);
        return ResponseEntity.status(HttpStatus.CREATED).body(participant);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'USER')")
    @DeleteMapping("/{eventId}/participants")
    public ResponseEntity<?> removeParticipant(
            @PathVariable Long eventId,
            @AuthenticationPrincipal Jwt jwt) {

        String username = jwt != null ? jwt.getSubject() : null;
        if (username == null) {
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
        }

        eventParticipantService.removeParticipant(eventId, username);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }
}
