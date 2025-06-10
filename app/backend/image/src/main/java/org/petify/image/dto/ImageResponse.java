package org.petify.image.dto;

import java.io.Serializable;
import java.time.LocalDateTime;

public record ImageResponse(
        Long id,
        String imageName,
        String imageType,
        String imageData,
        Long entityId,
        String entityType,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) implements Serializable {}
