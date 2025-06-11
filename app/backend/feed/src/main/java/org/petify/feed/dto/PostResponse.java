package org.petify.feed.dto;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.util.List;

public record PostResponse(
        Long id,
        Long shelterId, 
        String title,
        String shortDescription,

        Long mainImageId,
        String longDescription,
        Long fundraisingId,
        List<Long> imageIds,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) implements Serializable {}
