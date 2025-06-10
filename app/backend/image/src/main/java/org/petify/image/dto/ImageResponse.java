package org.petify.image.dto;

import java.io.Serializable;
import java.time.LocalDateTime;

public record ImageResponse(
        Long id,
        Long entityId,
        String entityType,
        String imageName,
        String imageType,
        LocalDateTime createdAt,
        String imageData
) implements Serializable {}
