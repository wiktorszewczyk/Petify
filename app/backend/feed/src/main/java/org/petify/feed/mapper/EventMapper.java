package org.petify.feed.mapper;

import org.petify.feed.dto.EventRequest;
import org.petify.feed.dto.EventResponse;
import org.petify.feed.model.Event;

import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;
import org.mapstruct.ReportingPolicy;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE, componentModel = MappingConstants.ComponentModel.SPRING)
public interface EventMapper {
    Event toEntity(EventRequest eventRequest);

    EventResponse toDto(Event event);
}
