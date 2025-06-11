package org.petify.feed.dto;

import java.io.Serializable;
import java.time.LocalDateTime;

public record EventParticipantResponse(
        Long id,
        Long eventId,
        String username,
        LocalDateTime createdAt
) implements Serializable {}
