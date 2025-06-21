package org.petify.chat.dto;

import java.time.LocalDateTime;

public record ChatRoomDTO(
        Long id,
        Long petId,
        String userName,
        String shelterName,
        long unreadCount,
        LocalDateTime lastMessageTimestamp
) {}
