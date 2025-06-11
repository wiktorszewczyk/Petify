package org.petify.feed.service;

import org.petify.feed.dto.EventParticipantResponse;
import org.petify.feed.exception.AlreadyParticipatingException;
import org.petify.feed.exception.FeedItemNotFoundException;
import org.petify.feed.exception.MaxEventCapacityReachedException;
import org.petify.feed.mapper.EventParticipantMapper;
import org.petify.feed.model.Event;
import org.petify.feed.model.EventParticipant;
import org.petify.feed.repository.EventParticipantRepository;
import org.petify.feed.repository.EventRepository;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@RequiredArgsConstructor
@Service
public class EventParticipantService {
    private final EventRepository eventRepository;
    private final EventParticipantRepository eventParticipantRepository;
    private final EventParticipantMapper eventParticipantMapper;

    public List<EventParticipantResponse> getParticipantsByEventId(Long eventId) {
        return eventParticipantRepository.findAllByEventId(eventId).stream()
                .map(eventParticipantMapper::toDto)
                .toList();
    }

    public List<EventParticipantResponse> getEventsByUsername(String username) {
        return eventParticipantRepository.findAllByUsername(username).stream()
                .map(eventParticipantMapper::toDto)
                .toList();
    }

    public int countParticipantsByEventId(Long eventId) {
        return eventParticipantRepository.countByEventId(eventId);
    }

    @Transactional
    public EventParticipantResponse addParticipant(Long eventId, String username) {
        if (eventParticipantRepository.findByEventIdAndUsername(eventId, username).isPresent()) {
            throw new AlreadyParticipatingException(eventId, username);
        }

        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new FeedItemNotFoundException(eventId, "Event"));
        if (event.getCapacity() != null && event.getCapacity() > 0
                && eventParticipantRepository.countByEventId(eventId) >= event.getCapacity()) {
            throw new MaxEventCapacityReachedException(eventId, event.getCapacity());
        }

        EventParticipant participant = new EventParticipant();
        participant.setEventId(eventId);
        participant.setUsername(username);

        participant = eventParticipantRepository.save(participant);
        return eventParticipantMapper.toDto(participant);
    }

    @Transactional
    public void removeParticipant(Long eventId, String username) {
        EventParticipant participant = eventParticipantRepository.findByEventIdAndUsername(eventId, username)
                .orElseThrow(() -> new FeedItemNotFoundException(username, "Event Participant"));
        eventParticipantRepository.delete(participant);
    }
}
