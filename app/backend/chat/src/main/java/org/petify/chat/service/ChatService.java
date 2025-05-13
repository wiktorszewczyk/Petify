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
import org.springframework.security.access.AccessDeniedException;
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

    /* ======================== SEND / RECEIVE ======================== */
    public void handleIncoming(Long roomId, String content, String login) {

        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> new IllegalStateException("Pokój nie istnieje: " + roomId));

        if (!isParticipant(room, login))
            throw new AccessDeniedException("Nie jesteś uczestnikiem tego czatu");

        boolean fromShelter = login.equals(room.getShelterName());

        ChatMessage saved = msgRepo.save(
                new ChatMessage(null, roomId, login, content, LocalDateTime.now())
        );

        String recipient = fromShelter ? room.getUserName() : room.getShelterName();

        broker.convertAndSendToUser(
                recipient,
                "/queue/chat/" + roomId,
                map(saved, room)
        );
    }

    /* ======================== LIST / HISTORY ======================== */
    @Transactional(readOnly = true)
    public List<ChatRoomDTO> myRooms(String login) {
        return roomRepo.findAllByUserNameOrShelterName(login, login)
                .stream()
                .filter(r -> visibleFor(r, login))
                .map(this::map)
                .toList();
    }

    @Transactional(readOnly = true)
    public Page<ChatMessageDTO> history(Long roomId, int page, int size) {
        return msgRepo.findByRoomIdOrderByTimestampDesc(roomId,
                        PageRequest.of(page, size))
                .map(m -> map(m, null));
    }

    /* =====================  USER  -> create/open  ==================== */
    public ChatRoomDTO openForUser(Long petId, String userLogin) {

        String shelterOwner = shelterClient.getShelterOwner(petId);

        ChatRoom room = roomRepo.findByPetIdAndUserName(petId, userLogin)
                .orElseGet(() -> new ChatRoom(
                        null, petId, userLogin, shelterOwner, true, true));

        room.setUserVisible(true);        // przywróć, jeśli było ukryte
        roomRepo.save(room);
        return map(room);
    }

    /* =====================  SHELTER -> open by id  =================== */
    public ChatRoomDTO openById(Long roomId, String login) {
        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> new IllegalStateException("Pokój nie istnieje"));
        if (!isParticipant(room, login))
            throw new AccessDeniedException("To nie Twój pokój");
        if (login.equals(room.getShelterName())) {
            room.setShelterVisible(true);
            roomRepo.save(room);
        }
        return map(room);
    }

    /* =====================  HIDE room (pojedyncza strona)  =========== */
    public void hideRoom(Long roomId, String login) {
        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> new IllegalStateException("Pokój nie istnieje"));

        if (!isParticipant(room, login))
            throw new AccessDeniedException("Nie jesteś uczestnikiem");

        if (login.equals(room.getUserName()))       room.setUserVisible(false);
        else                                        room.setShelterVisible(false);

        roomRepo.save(room);
    }

    /* ======================== HELPERS ================================ */
    private boolean isParticipant(ChatRoom r, String login) {
        return login.equals(r.getUserName()) || login.equals(r.getShelterName());
    }
    private boolean visibleFor(ChatRoom r, String login) {
        return login.equals(r.getUserName())    ? r.isUserVisible()
                : login.equals(r.getShelterName()) ? r.isShelterVisible()
                : false;
    }

    /* ======================== MAPERY ================================ */
    private ChatRoomDTO map(ChatRoom r) {
        return new ChatRoomDTO(r.getId(), r.getPetId(), r.getUserName(), r.getShelterName());
    }
    private ChatMessageDTO map(ChatMessage m, ChatRoom r) {
        return new ChatMessageDTO(m.getId(), m.getRoomId(),
                r != null ? r.getPetId() : null, m.getSender(), m.getContent(), m.getTimestamp());
    }
}
