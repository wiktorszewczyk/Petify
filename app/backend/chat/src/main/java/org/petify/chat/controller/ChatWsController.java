package org.petify.chat.controller;

import org.petify.chat.service.ChatService;

import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Controller;

import java.security.Principal;

@Controller
@RequiredArgsConstructor
public class ChatWsController {
    private final ChatService chatService;

    @MessageMapping("/chat/{roomId}")
    public void incoming(@DestinationVariable Long roomId,
                         @Payload String content,
                         Principal principal) {

        String login = principal.getName();
        chatService.handleIncoming(roomId, content, login);
    }
}
