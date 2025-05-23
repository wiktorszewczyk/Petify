package org.petify.chat.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class ChatService {

    private static final int MAX_MESSAGE_LENGTH = 1000;
    private static final int MAX_PAGE_SIZE = 100;
    private static final int MIN_PAGE_SIZE = 1;

    private final ChatRoomRepository roomRepo;
    private final ChatMessageRepository msgRepo;
    private final ShelterClient shelterClient;
    private final SimpMessagingTemplate broker;

    public void handleIncoming(Long roomId, String content, String login) {
        validateRoomId(roomId);
        validateMessageContent(content);
        validateLogin(login);

        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> new ChatNotFoundException("Chat room with ID " + roomId + " not found"));

        checkParticipantOrAdmin(room, login);

        boolean fromShelter = login.equals(room.getShelterName());

        if (fromShelter && !room.isUserVisible()) room.setUserVisible(true);
        if (!fromShelter && !room.isShelterVisible()) room.setShelterVisible(true);
        roomRepo.save(room);

        ChatMessage saved = msgRepo.save(
                new ChatMessage(null, roomId, login, content.trim(), LocalDateTime.now())
        );

        String recipient = fromShelter ? room.getUserName() : room.getShelterName();

        if (Objects.equals(recipient, login)) {
            throw new InvalidRoomStateException("Cannot send messages to yourself");
        }

        broker.convertAndSendToUser(recipient,
                "/queue/chat/" + roomId,
                map(saved, room));

        long totalUnread = totalUnreadFor(recipient);
        broker.convertAndSendToUser(recipient, "/queue/unread", totalUnread);

        log.info("Message sent from {} to {} in room {}", login, recipient, roomId);
    }

    @Transactional(readOnly = true)
    public List<ChatRoomDTO> myRooms(String login) {
        validateLogin(login);

        return roomRepo.findAllByUserNameOrShelterName(login, login)
                .stream()
                .filter(r -> visibleFor(r, login))
                .map(r -> map(r, login))
                .toList();
    }

    @Transactional(readOnly = true)
    public Page<ChatMessageDTO> history(Long roomId, String login, int page, int size) {
        validateRoomId(roomId);
        validateLogin(login);
        validatePaginationParams(page, size);

        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> new ChatNotFoundException("Chat room with ID " + roomId + " not found"));

        checkParticipantOrAdmin(room, login);

        LocalDateTime afterHidden = login.equals(room.getUserName())
                ? room.getUserHiddenAt()
                : room.getShelterHiddenAt();

        PageRequest pr = PageRequest.of(page, size);
        Page<ChatMessageDTO> result = (afterHidden == null
                ? msgRepo.findByRoomIdOrderByTimestampDesc(roomId, pr)
                : msgRepo.findByRoomIdAndTimestampAfterOrderByTimestampDesc(roomId, afterHidden, pr))
                .map(m -> map(m, room));

        markAsRead(room, login);
        return result;
    }

    public ChatRoomDTO openForUser(Long petId, String userLogin) {
        validatePetId(petId);
        validateLogin(userLogin);

        String shelterOwner;
        try {
            shelterOwner = shelterClient.getShelterOwner(petId);
        } catch (Exception e) {
            log.error("Failed to get shelter owner for pet {}", petId, e);
            throw new ShelterServiceUnavailableException("Unable to fetch pet information. Please try again later.");
        }

        if (shelterOwner == null || shelterOwner.isBlank()) {
            throw new ChatNotFoundException("Shelter owner not found for pet with ID " + petId);
        }

        if (userLogin.equals(shelterOwner)) {
            throw new ChatAccessDeniedException("You cannot chat with your own pet");
        }

        ChatRoom room = roomRepo.findByPetIdAndUserName(petId, userLogin)
                .orElseGet(() -> new ChatRoom(
                        null, petId, userLogin, shelterOwner,
                        true, true, null, null,
                        LocalDateTime.now(),
                        null));

        room.setUserVisible(true);
        roomRepo.save(room);

        log.info("Opened chat room for user {} and pet {}", userLogin, petId);
        return map(room, userLogin);
    }

    public ChatRoomDTO openById(Long roomId, String login) {
        validateRoomId(roomId);
        validateLogin(login);

        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> new ChatNotFoundException("Chat room with ID " + roomId + " not found"));

        checkParticipantOrAdmin(room, login);

        if (login.equals(room.getShelterName())) {
            room.setShelterVisible(true);
        }
        roomRepo.save(room);

        markAsRead(room, login);
        return map(room, login);
    }

    public void hideRoom(Long roomId, String login) {
        validateRoomId(roomId);
        validateLogin(login);

        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> new ChatNotFoundException("Chat room with ID " + roomId + " not found"));

        checkParticipantOrAdmin(room, login);

        LocalDateTime now = LocalDateTime.now();

        if (login.equals(room.getUserName())) {
            if (!room.isUserVisible()) {
                throw new InvalidRoomStateException("Room is already hidden for the user");
            }
            room.setUserVisible(false);
            room.setUserHiddenAt(now);
        } else if (login.equals(room.getShelterName())) {
            if (!room.isShelterVisible()) {
                throw new InvalidRoomStateException("Room is already hidden for the shelter");
            }
            room.setShelterVisible(false);
            room.setShelterHiddenAt(now);
        }

        roomRepo.save(room);

        if (!room.isUserVisible() && !room.isShelterVisible()) {
            msgRepo.deleteByRoomId(room.getId());
            roomRepo.delete(room);
            log.info("Deleted chat room {} as it was hidden by both parties", roomId);
        } else {
            log.info("Room {} hidden by {}", roomId, login);
        }
    }

    public long totalUnreadFor(String login) {
        validateLogin(login);

        return roomRepo.findAllByUserNameOrShelterName(login, login).stream()
                .filter(r -> visibleFor(r, login))
                .mapToLong(r -> unreadFor(r, login))
                .sum();
    }

    private void validateRoomId(Long roomId) {
        if (roomId == null || roomId <= 0) {
            throw new InvalidChatParameterException("Room ID must be a positive number");
        }
    }

    private void validatePetId(Long petId) {
        if (petId == null || petId <= 0) {
            throw new InvalidChatParameterException("Pet ID must be a positive number");
        }
    }

    private void validateLogin(String login) {
        if (login == null || login.trim().isEmpty()) {
            throw new InvalidChatParameterException("User login cannot be null or empty");
        }
    }

    private void validateMessageContent(String content) {
        if (content == null || content.trim().isEmpty()) {
            throw new InvalidMessageException("Message content cannot be empty");
        }
        if (content.length() > MAX_MESSAGE_LENGTH) {
            throw new InvalidMessageException("Message exceeds maximum length of " + MAX_MESSAGE_LENGTH + " characters");
        }
    }

    private void validatePaginationParams(int page, int size) {
        if (page < 0) {
            throw new InvalidChatParameterException("Page index cannot be negative");
        }
        if (size < MIN_PAGE_SIZE || size > MAX_PAGE_SIZE) {
            throw new InvalidChatParameterException("Page size must be between " + MIN_PAGE_SIZE + " and " + MAX_PAGE_SIZE);
        }
    }

    private void checkParticipantOrAdmin(ChatRoom r, String login) {
        if (!isParticipant(r, login) && !isAdmin()) {
            throw new ChatAccessDeniedException("You do not have access to this chat room");
        }
    }

    private boolean isParticipant(ChatRoom r, String login) {
        return login.equals(r.getUserName()) || login.equals(r.getShelterName());
    }

    private boolean isAdmin() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        return auth != null && auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
    }

    private ChatRoomDTO map(ChatRoom r, String login) {
        return new ChatRoomDTO(
                r.getId(),
                r.getPetId(),
                r.getUserName(),
                r.getShelterName(),
                unreadFor(r, login));
    }

    private ChatMessageDTO map(ChatMessage m, ChatRoom r) {
        return new ChatMessageDTO(m.getId(), m.getRoomId(),
                r != null ? r.getPetId() : null,
                m.getSender(), m.getContent(), m.getTimestamp());
    }

    private long unreadFor(ChatRoom r, String login) {
        LocalDateTime after = login.equals(r.getUserName())
                ? r.getUserLastReadAt()
                : r.getShelterLastReadAt();

        return (after == null)
                ? msgRepo.countByRoomIdAndSenderNot(r.getId(), login)
                : msgRepo.countByRoomIdAndTimestampAfterAndSenderNot(r.getId(), after, login);
    }

    private void markAsRead(ChatRoom room, String login) {
        LocalDateTime now = LocalDateTime.now();
        if (login.equals(room.getUserName())) {
            room.setUserLastReadAt(now);
        } else if (login.equals(room.getShelterName())) {
            room.setShelterLastReadAt(now);
        }
        roomRepo.save(room);
    }

    private boolean visibleFor(ChatRoom r, String login) {
        return login.equals(r.getUserName()) ? r.isUserVisible()
                : login.equals(r.getShelterName()) ? r.isShelterVisible()
                : false;
    }
}