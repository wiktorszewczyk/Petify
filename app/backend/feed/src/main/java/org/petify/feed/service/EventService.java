package org.petify.feed.service;

import org.petify.feed.dto.EventRequest;
import org.petify.feed.dto.EventResponse;
import org.petify.feed.exception.FeedItemNotFoundException;
import org.petify.feed.mapper.EventMapper;
import org.petify.feed.model.Event;
import org.petify.feed.repository.EventRepository;
import org.petify.feed.specification.FeedItemSpecification;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
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

    public List<EventResponse> getAllIncomingEvents(int days) {
        LocalDateTime tillDate = LocalDateTime.now().plusDays(days);
        return eventRepository.findAllIncomingEvents(tillDate, LocalDateTime.now()).stream()
                .map(eventMapper::toDto)
                .toList();
    }

    public List<EventResponse> searchIncomingEvents(int days, String content) {
        LocalDateTime tillDate = LocalDateTime.now().plusDays(days);
        Specification<Event> spec = FeedItemSpecification.hasContent(content);
        return eventRepository.findAll(spec).stream()
                .filter(event -> event.getStartDate().isBefore(tillDate) && event.getEndDate().isAfter(LocalDateTime.now()))
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
        existingEvent.setTitle(eventRequest.title());
        existingEvent.setShortDescription(eventRequest.shortDescription());
        existingEvent.setStartDate(eventRequest.startDate());
        existingEvent.setEndDate(eventRequest.endDate());
        existingEvent.setAddress(eventRequest.address());

        existingEvent.setMainImageId(eventRequest.mainImageId());
        existingEvent.setLongDescription(eventRequest.longDescription());
        existingEvent.setFundraisingId(eventRequest.fundraisingId());
        existingEvent.setLatitude(eventRequest.latitude());
        existingEvent.setLongitude(eventRequest.longitude());
        existingEvent.setCapacity(eventRequest.capacity());

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
