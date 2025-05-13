package org.petify.chat.service;

import lombok.RequiredArgsConstructor;
import org.petify.chat.client.ShelterClient;
import org.petify.chat.dto.ChatMessageDTO;
import org.petify.chat.dto.ChatRoomDTO;
import org.petify.chat.model.ChatMessage;
import org.petify.chat.model.ChatRoom;
import org.petify.chat.repository.ChatMessageRepository;
import org.petify.chat.repository.ChatRoomRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class ChatService {

    private static final Logger log = LoggerFactory.getLogger(ChatService.class);

    private final ChatRoomRepository roomRepo;
    private final ChatMessageRepository msgRepo;
    private final ShelterClient shelterClient;
    private final SimpMessagingTemplate broker;

    public void handleIncoming(Long roomId, String content, String login) {
        // 1) Pobierz pokój po roomId
        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> new IllegalStateException("Pokój czatu nie istnieje: " + roomId));

        // 2) Ustal, czy nadawca to schronisko
        boolean fromShelter = login.equals(room.getShelterName());
        log.info("[CHAT] handleIncoming: sender={} roomId={} fromShelter={} userName={} shelterName={}",
                login, roomId, fromShelter, room.getUserName(), room.getShelterName());

        // 3) Zapisz wiadomość
        ChatMessage saved = msgRepo.save(
                new ChatMessage(null, roomId, login, content, LocalDateTime.now())
        );

        // 4) Wyznacz odbiorcę – jeśli pisze shelter, to user; jeśli user, to shelter
        String recipient = fromShelter
                ? room.getUserName()
                : room.getShelterName();

        log.info("[CHAT] sending to={} destination=/user/{}/queue/chat/{}",
                recipient, recipient, roomId);

        // 5) Wyślij do subskrybenta pod /user/{recipient}/queue/chat/{roomId}
        broker.convertAndSendToUser(
                recipient,
                "/queue/chat/" + roomId,
                map(saved, room)
        );
    }


    @Transactional(readOnly = true)
    public List<ChatRoomDTO> myRooms(String login) {
        return roomRepo.findAllByUserNameOrShelterName(login, login)
                .stream()
                .map(this::map)
                .toList();
    }

    @Transactional(readOnly = true)
    public Page<ChatMessageDTO> history(Long roomId, int page, int size) {
        return msgRepo.findByRoomIdOrderByTimestampDesc(roomId, PageRequest.of(page, size))
                .map(m -> map(m, null));
    }

    @Transactional
    public ChatRoomDTO createRoom(Long petId, String userName) {
        String shelterOwner = shelterClient.getShelterOwner(petId);
        ChatRoom room = new ChatRoom(null, petId, userName, shelterOwner);
        room = roomRepo.save(room);
        return new ChatRoomDTO(room.getId(), room.getPetId(), room.getUserName(), room.getShelterName());
    }

    /* ----- mapery ----- */

    private ChatRoomDTO map(ChatRoom r) {
        return new ChatRoomDTO(r.getId(), r.getPetId(), r.getUserName(), r.getShelterName());
    }

    private ChatMessageDTO map(ChatMessage m, ChatRoom r) {
        return new ChatMessageDTO(
                m.getId(),
                m.getRoomId(),
                r != null ? r.getPetId() : null,
                m.getSender(),
                m.getContent(),
                m.getTimestamp()
        );
    }
}
