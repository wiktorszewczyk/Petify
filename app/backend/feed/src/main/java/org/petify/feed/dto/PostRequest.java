package org.petify.feed.dto;

import jakarta.validation.constraints.NotBlank;

import java.io.Serializable;
import java.util.List;

public record PostRequest(
        Long mainImageId,
        @NotBlank String title,
        @NotBlank String shortDescription,
        String longDescription,
        Long fundraisingId,
        List<Long> imageIds
) implements Serializable {}
