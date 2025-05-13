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
@RequestMapping("/api/chat")
public class ChatRestController {

    private final ChatService chatService;

    /* ---------- listy ---------- */
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

    /* ---------- USER: otwiera przez petId ---------- */
    @GetMapping("/room/{petId}")
    public ChatRoomDTO openRoomForUser(@PathVariable Long petId, Principal principal) {
        return chatService.openForUser(petId, principal.getName());
    }

    /* ---------- SHELTER & USER: otwiera po id ---------- */
    @GetMapping("/rooms/{roomId}")
    public ChatRoomDTO openRoomById(@PathVariable Long roomId, Principal p) {
        return chatService.openById(roomId, p.getName());
    }

    /* ---------- hide only for caller ---------- */
    @DeleteMapping("/rooms/{roomId}")
    public ResponseEntity<Void> hideRoom(@PathVariable Long roomId, Principal p) {
        chatService.hideRoom(roomId, p.getName());
        return ResponseEntity.noContent().build();
    }
}
