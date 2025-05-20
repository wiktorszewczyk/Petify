package org.petify.chat.service;

import lombok.RequiredArgsConstructor;
import org.petify.chat.client.ShelterClient;
import org.petify.chat.dto.ChatMessageDTO;
import org.petify.chat.dto.ChatRoomDTO;
import org.petify.chat.exception.*;
import org.petify.chat.model.ChatMessage;
import org.petify.chat.model.ChatRoom;
import org.petify.chat.repository.ChatMessageRepository;
import org.petify.chat.repository.ChatRoomRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

@Service
@RequiredArgsConstructor
@Transactional
public class ChatService {

    private static final int MAX_MESSAGE_LENGTH = 1000;
    private static final int MAX_PAGE_SIZE      = 100;

    private final ChatRoomRepository roomRepo;
    private final ChatMessageRepository msgRepo;
    private final ShelterClient shelterClient;
    private final SimpMessagingTemplate broker;

    public void handleIncoming(Long roomId, String content, String login) {
        if (roomId == null || roomId <= 0)
            throw new BadRequestException("Room ID must be positive");
        if (content == null || content.isBlank())
            throw new BadRequestException("Message content is empty");
        if (content.length() > MAX_MESSAGE_LENGTH)
            throw new BadRequestException("Message exceeds max length of " + MAX_MESSAGE_LENGTH + " chars");

        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> new NotFoundException("Chat room does not exist: " + roomId));

        if (!isParticipant(room, login))
            throw new ForbiddenOperationException("You are not a participant of this chat");

        boolean fromShelter = login.equals(room.getShelterName());

        if (fromShelter && !room.isUserVisible()) {
            room.setUserVisible(true);
        }
        if (!fromShelter && !room.isShelterVisible()) {
            room.setShelterVisible(true);
        }
        roomRepo.save(room);

        ChatMessage saved = msgRepo.save(
                new ChatMessage(null, roomId, login, content, LocalDateTime.now())
        );

        String recipient = fromShelter ? room.getUserName() : room.getShelterName();

        if (Objects.equals(recipient, login)) {
            throw new ConflictException("Cannot send messages to yourself");
        }

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
                .filter(r -> visibleFor(r, login))
                .map(this::map)
                .toList();
    }

    @Transactional(readOnly = true)
    public Page<ChatMessageDTO> history(Long roomId, String login, int page, int size) {
        if (roomId == null || roomId <= 0)
            throw new BadRequestException("Room ID must be positive");
        if (page < 0)
            throw new BadRequestException("Page index cannot be negative");
        if (size <= 0 || size > MAX_PAGE_SIZE)
            throw new BadRequestException("Page size must be within 1-" + MAX_PAGE_SIZE);

        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> new NotFoundException("Chat room does not exist"));

        if (!isParticipant(room, login))
            throw new ForbiddenOperationException("You are not a participant of this chat");

        LocalDateTime after = login.equals(room.getUserName())
                ? room.getUserHiddenAt()
                : room.getShelterHiddenAt();

        PageRequest pr = PageRequest.of(page, size);

        return (after == null
                ? msgRepo.findByRoomIdOrderByTimestampDesc(roomId, pr)
                : msgRepo.findByRoomIdAndTimestampAfterOrderByTimestampDesc(roomId, after, pr))
                .map(m -> map(m, room));
    }

    public ChatRoomDTO openForUser(Long petId, String userLogin) {
        if (petId == null || petId <= 0)
            throw new BadRequestException("petId must be positive");

        String shelterOwner = shelterClient.getShelterOwner(petId);
        if (shelterOwner == null || shelterOwner.isBlank())
            throw new ConflictException("Shelter owner not found for petId=" + petId);

        if (userLogin.equals(shelterOwner))
            throw new ForbiddenOperationException("You cannot chat with your own pet");

        ChatRoom room = roomRepo.findByPetIdAndUserName(petId, userLogin)
                .orElseGet(() -> new ChatRoom(
                        null, petId, userLogin, shelterOwner, true, true, null, null));

        room.setUserVisible(true);
        roomRepo.save(room);
        return map(room);
    }

    public ChatRoomDTO openById(Long roomId, String login) {
        if (roomId == null || roomId <= 0)
            throw new BadRequestException("Room ID must be positive");

        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> new NotFoundException("Chat room does not exist"));

        if (!isParticipant(room, login))
            throw new ForbiddenOperationException("This is not your room");

        if (login.equals(room.getShelterName())) {
            room.setShelterVisible(true);
            roomRepo.save(room);
        }
        return map(room);
    }

    public void hideRoom(Long roomId, String login) {
        if (roomId == null || roomId <= 0)
            throw new BadRequestException("Room ID must be positive");

        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> new NotFoundException("Chat room does not exist"));

        if (!isParticipant(room, login))
            throw new ForbiddenOperationException("You are not a participant of this chat");

        LocalDateTime now = LocalDateTime.now();

        if (login.equals(room.getUserName())) {
            if (!room.isUserVisible())
                throw new ConflictException("Room is already hidden for the user");
            room.setUserVisible(false);
            room.setUserHiddenAt(now);
        } else {
            if (!room.isShelterVisible())
                throw new ConflictException("Room is already hidden for the shelter");
            room.setShelterVisible(false);
            room.setShelterHiddenAt(now);
        }
        roomRepo.save(room);
    }

    private boolean isParticipant(ChatRoom r, String login) {
        return login.equals(r.getUserName()) || login.equals(r.getShelterName());
    }
    private boolean visibleFor(ChatRoom r, String login) {
        return login.equals(r.getUserName())      ? r.isUserVisible()
                : login.equals(r.getShelterName())   ? r.isShelterVisible()
                : false;
    }

    private ChatRoomDTO map(ChatRoom r) {
        return new ChatRoomDTO(r.getId(), r.getPetId(), r.getUserName(), r.getShelterName());
    }
    private ChatMessageDTO map(ChatMessage m, ChatRoom r) {
        return new ChatMessageDTO(m.getId(), m.getRoomId(),
                r != null ? r.getPetId() : null,
                m.getSender(), m.getContent(), m.getTimestamp());
    }
}
