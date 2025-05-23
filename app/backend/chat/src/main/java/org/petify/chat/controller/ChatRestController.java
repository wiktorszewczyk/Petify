package org.petify.chat.controller;

import lombok.RequiredArgsConstructor;
import org.petify.chat.dto.ChatMessageDTO;
import org.petify.chat.dto.ChatRoomDTO;
import org.petify.chat.service.ChatService;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/chat")
@RequiredArgsConstructor
public class ChatRestController {

    private final ChatService chatService;

    @PreAuthorize("hasAnyRole('ADMIN','USER','SHELTER','VOLUNTEER')")
    @GetMapping("/rooms")
    public List<ChatRoomDTO> rooms(@AuthenticationPrincipal Jwt jwt) {
        return chatService.myRooms(jwt.getSubject());
    }

    @PreAuthorize("hasAnyRole('ADMIN','USER','SHELTER','VOLUNTEER')")
    @GetMapping("/history/{roomId}")
    public Page<ChatMessageDTO> history(@PathVariable Long roomId,
                                        @RequestParam(defaultValue = "0")  int page,
                                        @RequestParam(defaultValue = "40") int size,
                                        @AuthenticationPrincipal Jwt jwt) {

        return chatService.history(roomId, jwt.getSubject(), page, size);
    }

    @PreAuthorize("hasAnyRole('ADMIN','USER','VOLUNTEER')")
    @GetMapping("/room/{petId}")
    public ChatRoomDTO openRoomForUser(@PathVariable Long petId,
                                       @AuthenticationPrincipal Jwt jwt) {

        return chatService.openForUser(petId, jwt.getSubject());
    }

    @PreAuthorize("hasAnyRole('ADMIN','USER','SHELTER','VOLUNTEER')")
    @GetMapping("/rooms/{roomId}")
    public ChatRoomDTO openRoomById(@PathVariable Long roomId,
                                    @AuthenticationPrincipal Jwt jwt) {

        return chatService.openById(roomId, jwt.getSubject());
    }

    @PreAuthorize("hasAnyRole('ADMIN','USER','SHELTER','VOLUNTEER')")
    @DeleteMapping("/rooms/{roomId}")
    public ResponseEntity<Void> hideRoom(@PathVariable Long roomId,
                                         @AuthenticationPrincipal Jwt jwt) {

        chatService.hideRoom(roomId, jwt.getSubject());
        return ResponseEntity.noContent().build();
    }

    @PreAuthorize("hasAnyRole('ADMIN','USER','SHELTER','VOLUNTEER')")
    @GetMapping("/unread/count")
    public long totalUnread(@AuthenticationPrincipal Jwt jwt) {
        return chatService.totalUnreadFor(jwt.getSubject());
    }
}