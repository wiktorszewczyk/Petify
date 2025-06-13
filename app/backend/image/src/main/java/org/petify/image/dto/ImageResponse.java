package org.petify.image.dto;

import java.io.Serializable;
import java.time.LocalDateTime;

public record ImageResponse(
        Long id,
        Long entityId,
        String entityType,
        String imageUrl,
        LocalDateTime createdAt
) implements Serializable {}
