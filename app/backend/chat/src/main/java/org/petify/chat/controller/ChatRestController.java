package org.petify.chat.controller;

import lombok.RequiredArgsConstructor;
import org.petify.chat.dto.ChatMessageDTO;
import org.petify.chat.dto.ChatRoomDTO;
import org.petify.chat.dto.CreateChatRoomRequest;
import org.petify.chat.service.ChatService;
import org.springframework.data.domain.Page;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/api/chat")
public class ChatRestController {

    private final ChatService chatService;

    @GetMapping("/rooms")
    public List<ChatRoomDTO> rooms(Principal p) {
        return chatService.myRooms(p.getName());
    }

    @GetMapping("/history/{roomId}")
    public Page<ChatMessageDTO> history(@PathVariable Long roomId,
                                        @RequestParam(defaultValue = "0") int page,
                                        @RequestParam(defaultValue = "40") int size) {
        return chatService.history(roomId, page, size);
    }

    @PostMapping("/rooms")
    public ChatRoomDTO createRoom(
            @RequestBody CreateChatRoomRequest req,
            Principal principal) {
        return chatService.createRoom(req.petId(), principal.getName());
    }
}
