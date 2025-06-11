package org.petify.feed.dto;

import java.io.Serializable;
import java.time.LocalDate;
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
        LocalDate createdAt,
        LocalDate updatedAt
) implements Serializable {}
