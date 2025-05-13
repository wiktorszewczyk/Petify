package org.petify.chat.dto;

public record ChatRoomDTO(
        Long id,
        Long petId,
        String userName,
        String shelterName
) {}
