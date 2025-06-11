package org.petify.feed.service;

import org.petify.feed.dto.EventRequest;
import org.petify.feed.dto.EventResponse;
import org.petify.feed.exception.FeedItemNotFoundException;
import org.petify.feed.mapper.EventMapper;
import org.petify.feed.model.Event;
import org.petify.feed.repository.EventRepository;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@RequiredArgsConstructor
@Service
public class EventService {
    private final EventRepository eventRepository;
    private final EventMapper eventMapper;

    public EventResponse getEventById(Long eventId) {
        Event event = eventRepository.findById(eventId)
                .orElseThrow(() -> new FeedItemNotFoundException(eventId, "Event"));
        return eventMapper.toDto(event);
    }

    public List<EventResponse> getEventsByShelterId(Long shelterId) {
        return eventRepository.findAllByShelterId(shelterId).stream()
                .map(eventMapper::toDto)
                .toList();
    }

    @Transactional
    public EventResponse createEvent(Long shelterId, EventRequest eventRequest) {
        Event event = eventMapper.toEntity(eventRequest);
        event.setShelterId(shelterId);

        event = eventRepository.save(event);
        return eventMapper.toDto(event);
    }

    @Transactional
    public EventResponse updateEvent(Long eventId, EventRequest eventRequest) {
        Event existingEvent = eventRepository.findById(eventId)
                .orElseThrow(() -> new FeedItemNotFoundException(eventId, "Event"));
        existingEvent.setMainImageId(eventRequest.getMainImageId());
        existingEvent.setTitle(eventRequest.getTitle());
        existingEvent.setShortDescription(eventRequest.getShortDescription());
        existingEvent.setLongDescription(eventRequest.getLongDescription());
        existingEvent.setFundraisingId(eventRequest.getFundraisingId());
        existingEvent.setStartDate(eventRequest.getStartDate());
        existingEvent.setEndDate(eventRequest.getEndDate());
        existingEvent.setAddress(eventRequest.getAddress());
        existingEvent.setLatitude(eventRequest.getLatitude());
        existingEvent.setLongitude(eventRequest.getLongitude());
        existingEvent.setCapacity(eventRequest.getCapacity());

        existingEvent = eventRepository.save(existingEvent);
        return eventMapper.toDto(existingEvent);
    }

    @Transactional
    public void deleteEvent(Long eventId) {
        if (!eventRepository.existsById(eventId)) {
            throw new FeedItemNotFoundException(eventId, "Event");
        }
        eventRepository.deleteById(eventId);
    }
}
