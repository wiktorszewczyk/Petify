package org.petify.shelter.dto;

import java.io.Serializable;
import java.util.List;

public record SwipeResponse(
        List<PetResponseWithImages> pets,
        Long nextCursor
) implements Serializable {}
