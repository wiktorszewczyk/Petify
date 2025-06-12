package org.petify.feed.mapper;

import org.petify.feed.dto.EventParticipantResponse;
import org.petify.feed.model.EventParticipant;

import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;
import org.mapstruct.ReportingPolicy;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE, componentModel = MappingConstants.ComponentModel.SPRING)
public interface EventParticipantMapper {
    EventParticipantResponse toDto(EventParticipant eventParticipant);
}
