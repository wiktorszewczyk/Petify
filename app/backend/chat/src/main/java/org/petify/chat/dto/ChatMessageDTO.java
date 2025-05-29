package org.petify.chat.dto;

import java.time.LocalDateTime;

public record ChatMessageDTO(
        Long id,
        Long roomId,
        Long petId,
        String sender,
        String content,
        LocalDateTime timestamp
) {}
