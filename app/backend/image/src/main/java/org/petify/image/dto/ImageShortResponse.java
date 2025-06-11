package org.petify.image.dto;

import java.io.Serializable;
import java.time.LocalDateTime;

public record ImageShortResponse(
        Long id,
        Long entityId,
        String entityType,
        String imageName,
        LocalDateTime createdAt
) implements Serializable {}
