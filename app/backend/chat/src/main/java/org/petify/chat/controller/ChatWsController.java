package org.petify.chat.controller;

import lombok.RequiredArgsConstructor;
import org.petify.chat.model.ChatRoom;
import org.petify.chat.repository.ChatRoomRepository;
import org.petify.chat.service.ChatService;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Controller;

import java.security.Principal;

@Controller
@RequiredArgsConstructor
public class ChatWsController {
    private final ChatService chatService;
    private final ChatRoomRepository roomRepo;

    @MessageMapping("/chat/{roomId}")
    public void incoming(@DestinationVariable Long roomId,
                         @Payload String content,
                         Principal principal) {

        String login = principal.getName();
        chatService.handleIncoming(roomId, content, login);
    }
}
