package org.petify.chat.controller;

import lombok.RequiredArgsConstructor;
import org.petify.chat.dto.ChatMessageDTO;
import org.petify.chat.dto.ChatRoomDTO;
import org.petify.chat.service.ChatService;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/chat")
public class ChatRestController {

    private final ChatService chatService;

    @GetMapping("/rooms")
    public List<ChatRoomDTO> rooms(Principal p) {
        return chatService.myRooms(p.getName());
    }

    @GetMapping("/history/{roomId}")
    public Page<ChatMessageDTO> history(@PathVariable Long roomId,
                                        @RequestParam(defaultValue = "0") int page,
                                        @RequestParam(defaultValue = "40") int size,
                                        Principal principal) {

        return chatService.history(roomId, principal.getName(), page, size);
    }

    @GetMapping("/room/{petId}")
    public ChatRoomDTO openRoomForUser(@PathVariable Long petId, Principal principal) {
        return chatService.openForUser(petId, principal.getName());
    }

    @GetMapping("/rooms/{roomId}")
    public ChatRoomDTO openRoomById(@PathVariable Long roomId, Principal p) {
        return chatService.openById(roomId, p.getName());
    }

    @DeleteMapping("/rooms/{roomId}")
    public ResponseEntity<Void> hideRoom(@PathVariable Long roomId, Principal p) {
        chatService.hideRoom(roomId, p.getName());
        return ResponseEntity.noContent().build();
    }
}
