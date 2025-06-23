package org.petify.chat.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.chat.client.ShelterClient;
import org.petify.chat.dto.ChatMessageDTO;
import org.petify.chat.dto.ChatRoomDTO;
import org.petify.chat.exception.*;
import org.petify.chat.model.ChatMessage;
import org.petify.chat.model.ChatRoom;
import org.petify.chat.repository.ChatMessageRepository;
import org.petify.chat.repository.ChatRoomRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ChatServiceTest {

    @Mock
    private ChatRoomRepository roomRepository;

    @Mock
    private ChatMessageRepository messageRepository;

    @Mock
    private ShelterClient shelterClient;

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    @InjectMocks
    private ChatService chatService;

    private ChatRoom testRoom;
    private ChatMessage testMessage;

    @BeforeEach
    void setUp() {
        lenient().doNothing().when(messagingTemplate)
                .convertAndSendToUser(anyString(), anyString(), any());

        lenient().when(messageRepository.countByRoomIdAndSenderNot(anyLong(), anyString()))
                .thenReturn(0L);

        testRoom = new ChatRoom(
                1L,
                100L,
                "testuser",
                "shelter1",
                true,
                true,
                null,
                null,
                null,
                null,
                LocalDateTime.now()
        );

        testMessage = new ChatMessage(
                1L,
                1L,
                "testuser",
                "Test message",
                LocalDateTime.now()
        );
    }

    @Test
    void handleIncoming_ShouldSaveMessageAndNotify() {
        // given
        when(roomRepository.findById(1L)).thenReturn(Optional.of(testRoom));
        when(messageRepository.save(any(ChatMessage.class))).thenReturn(testMessage);
        when(roomRepository.save(any(ChatRoom.class))).thenReturn(testRoom);
        when(messageRepository.countByRoomIdAndSenderNot(anyLong(), anyString())).thenReturn(0L);

        // when
        chatService.handleIncoming(1L, "Test message", "testuser");

        // then
        verify(messageRepository).save(any(ChatMessage.class));
        verify(roomRepository).save(any(ChatRoom.class));
        verify(messagingTemplate).convertAndSendToUser(eq("shelter1"), eq("/queue/chat/1"), any());
        verify(messagingTemplate).convertAndSendToUser(eq("shelter1"), eq("/queue/unread"), eq(0L));
    }

    @Test
    void handleIncoming_ShouldThrowWhenRoomNotFound() {
        // given
        when(roomRepository.findById(1L)).thenReturn(Optional.empty());

        // when & then
        assertThatThrownBy(() -> chatService.handleIncoming(1L, "Test", "testuser"))
                .isInstanceOf(ChatNotFoundException.class)
                .hasMessageContaining("Chat room with ID 1 not found");
    }

    @Test
    void handleIncoming_ShouldThrowWhenMessageEmpty() {
        // when & then
        assertThatThrownBy(() -> chatService.handleIncoming(1L, "", "testuser"))
                .isInstanceOf(InvalidMessageException.class);
    }

    @Test
    void handleIncoming_ShouldThrowWhenMessageTooLong() {
        // given
        String longMessage = "a".repeat(1001);

        // when & then
        assertThatThrownBy(() -> chatService.handleIncoming(1L, longMessage, "testuser"))
                .isInstanceOf(InvalidMessageException.class);
    }

    @Test
    void handleIncoming_ShouldThrowWhenUserNotParticipant() {
        // given
        when(roomRepository.findById(1L)).thenReturn(Optional.of(testRoom));

        // when & then
        assertThatThrownBy(() -> chatService.handleIncoming(1L, "Test", "stranger"))
                .isInstanceOf(ChatAccessDeniedException.class);
    }

    @Test
    void handleIncoming_ShouldThrowWhenSendingToSelf() {
        // given
        testRoom.setShelterName("testuser"); // ten sam użytkownik jako shelter i user
        when(roomRepository.findById(1L)).thenReturn(Optional.of(testRoom));
        when(messageRepository.save(any(ChatMessage.class))).thenReturn(testMessage);

        // when & then
        assertThatThrownBy(() -> chatService.handleIncoming(1L, "Test", "testuser"))
                .isInstanceOf(InvalidRoomStateException.class)
                .hasMessageContaining("Cannot send messages to yourself");
    }

    @Test
    void handleIncoming_ShouldMakeRoomVisibleForRecipient() {
        // given
        ChatRoom invisibleRoom = new ChatRoom(
                1L, 100L, "testuser", "shelter1",
                false, true, null, null, null, null, LocalDateTime.now()
        );
        when(roomRepository.findById(1L)).thenReturn(Optional.of(invisibleRoom));
        when(messageRepository.save(any(ChatMessage.class))).thenReturn(testMessage);

        // when
        chatService.handleIncoming(1L, "Test", "shelter1");

        // then
        // handleIncoming zapisuje pokój tylko raz (po ustawieniu lastMessageTimestamp)
        verify(roomRepository).save(any(ChatRoom.class));
        assertThat(invisibleRoom.isUserVisible()).isTrue();
    }

    @Test
    void openForUser_ShouldCreateNewRoomWhenNotExists() {
        // given
        when(shelterClient.getShelterOwner(100L)).thenReturn("shelter1");
        when(roomRepository.findByPetIdAndUserName(100L, "testuser")).thenReturn(Optional.empty());
        when(roomRepository.save(any(ChatRoom.class))).thenReturn(testRoom);

        // when
        ChatRoomDTO result = chatService.openForUser(100L, "testuser");

        // then
        assertThat(result.id()).isEqualTo(1L);
        assertThat(result.petId()).isEqualTo(100L);
        verify(roomRepository).save(any(ChatRoom.class));
    }

    @Test
    void openForUser_ShouldReturnExistingRoom() {
        // given
        when(shelterClient.getShelterOwner(100L)).thenReturn("shelter1");
        when(roomRepository.findByPetIdAndUserName(100L, "testuser")).thenReturn(Optional.of(testRoom));

        // when
        ChatRoomDTO result = chatService.openForUser(100L, "testuser");

        // then
        assertThat(result.id()).isEqualTo(1L);
        verify(roomRepository, never()).save(any(ChatRoom.class));
    }

    @Test
    void openForUser_ShouldThrowWhenShelterOwnerNotFound() {
        // given
        when(shelterClient.getShelterOwner(100L)).thenReturn(null);

        // when & then
        assertThatThrownBy(() -> chatService.openForUser(100L, "testuser"))
                .isInstanceOf(ChatNotFoundException.class)
                .hasMessageContaining("Shelter owner not found");
    }

    @Test
    void openForUser_ShouldThrowWhenUserIsShelterOwner() {
        // given
        when(shelterClient.getShelterOwner(100L)).thenReturn("testuser");

        // when & then
        assertThatThrownBy(() -> chatService.openForUser(100L, "testuser"))
                .isInstanceOf(ChatAccessDeniedException.class)
                .hasMessageContaining("You cannot chat with your own pet");
    }

    @Test
    void openForUser_ShouldThrowWhenShelterServiceUnavailable() {
        // given
        when(shelterClient.getShelterOwner(100L)).thenThrow(new RuntimeException("Service down"));

        // when & then
        assertThatThrownBy(() -> chatService.openForUser(100L, "testuser"))
                .isInstanceOf(ShelterServiceUnavailableException.class);
    }

    @Test
    void openForUser_ShouldMakeRoomVisibleWhenHidden() {
        // given
        ChatRoom hiddenRoom = new ChatRoom(
                1L, 100L, "testuser", "shelter1",
                false, true, null, null, null, null, LocalDateTime.now()
        );
        when(shelterClient.getShelterOwner(100L)).thenReturn("shelter1");
        when(roomRepository.findByPetIdAndUserName(100L, "testuser")).thenReturn(Optional.of(hiddenRoom));

        // when
        chatService.openForUser(100L, "testuser");

        // then
        verify(roomRepository).save(any(ChatRoom.class));
        assertThat(hiddenRoom.isUserVisible()).isTrue();
    }

    @Test
    void openById_ShouldReturnRoomAndMarkAsRead() {
        // given
        when(roomRepository.findById(1L)).thenReturn(Optional.of(testRoom));

        // when
        ChatRoomDTO result = chatService.openById(1L, "testuser");

        // then
        assertThat(result.id()).isEqualTo(1L);
        verify(roomRepository).save(any(ChatRoom.class));
    }

    @Test
    void openById_ShouldThrowWhenRoomNotFound() {
        // given
        when(roomRepository.findById(1L)).thenReturn(Optional.empty());

        // when & then
        assertThatThrownBy(() -> chatService.openById(1L, "testuser"))
                .isInstanceOf(ChatNotFoundException.class);
    }

    @Test
    void openById_ShouldThrowWhenUserNotParticipant() {
        // given
        when(roomRepository.findById(1L)).thenReturn(Optional.of(testRoom));

        // when & then
        assertThatThrownBy(() -> chatService.openById(1L, "stranger"))
                .isInstanceOf(ChatAccessDeniedException.class);
    }

    @Test
    void openById_ShouldMakeShelterRoomVisible() {
        // given
        ChatRoom invisibleRoom = new ChatRoom(
                1L, 100L, "testuser", "shelter1",
                true, false, null, null, null, null, LocalDateTime.now()
        );
        when(roomRepository.findById(1L)).thenReturn(Optional.of(invisibleRoom));

        // when
        chatService.openById(1L, "shelter1");

        // then
        verify(roomRepository, times(2)).save(any(ChatRoom.class));
        assertThat(invisibleRoom.isShelterVisible()).isTrue();
    }

    @Test
    void myRooms_ShouldReturnVisibleRoomsOnly() {
        // given
        ChatRoom visibleRoom = new ChatRoom();
        visibleRoom.setId(1L);
        visibleRoom.setPetId(100L);
        visibleRoom.setUserName("testuser");
        visibleRoom.setShelterName("shelter1");
        visibleRoom.setUserVisible(true);

        ChatRoom hiddenRoom = new ChatRoom();
        hiddenRoom.setId(2L);
        hiddenRoom.setPetId(200L);
        hiddenRoom.setUserName("testuser");
        hiddenRoom.setShelterName("shelter2");
        hiddenRoom.setUserVisible(false);

        when(roomRepository.findAllRoomsForUserSorted("testuser"))
                .thenReturn(List.of(visibleRoom, hiddenRoom));

        // when
        List<ChatRoomDTO> result = chatService.myRooms("testuser");

        // then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).id()).isEqualTo(1L);
    }

    @Test
    void myRooms_ShouldThrowWhenLoginNull() {
        // when & then
        assertThatThrownBy(() -> chatService.myRooms(null))
                .isInstanceOf(InvalidChatParameterException.class);
    }

    @Test
    void history_ShouldReturnMessagesAndMarkAsRead() {
        // given
        Page<ChatMessage> messagePage = new PageImpl<>(List.of(testMessage));
        when(roomRepository.findById(1L)).thenReturn(Optional.of(testRoom));
        when(messageRepository.findByRoomIdOrderByTimestampDesc(eq(1L), any(PageRequest.class)))
                .thenReturn(messagePage);

        // when
        Page<ChatMessageDTO> result = chatService.history(1L, "testuser", 0, 20);

        // then
        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getContent().get(0).content()).isEqualTo("Test message");
        verify(roomRepository).save(any(ChatRoom.class));
    }

    @Test
    void history_ShouldThrowWhenInvalidPagination() {
        // when & then
        assertThatThrownBy(() -> chatService.history(1L, "testuser", -1, 20))
                .isInstanceOf(InvalidChatParameterException.class);

        assertThatThrownBy(() -> chatService.history(1L, "testuser", 0, 0))
                .isInstanceOf(InvalidChatParameterException.class);

        assertThatThrownBy(() -> chatService.history(1L, "testuser", 0, 101))
                .isInstanceOf(InvalidChatParameterException.class);
    }

    @Test
    void hideRoom_ShouldHideRoomForUser() {
        // given
        when(roomRepository.findById(1L)).thenReturn(Optional.of(testRoom));

        // when
        chatService.hideRoom(1L, "testuser");

        // then
        verify(roomRepository).save(any(ChatRoom.class));
        assertThat(testRoom.isUserVisible()).isFalse();
        assertThat(testRoom.getUserHiddenAt()).isNotNull();
    }

    @Test
    void hideRoom_ShouldHideRoomForShelter() {
        // given
        when(roomRepository.findById(1L)).thenReturn(Optional.of(testRoom));

        // when
        chatService.hideRoom(1L, "shelter1");

        // then
        verify(roomRepository).save(any(ChatRoom.class));
        assertThat(testRoom.isShelterVisible()).isFalse();
        assertThat(testRoom.getShelterHiddenAt()).isNotNull();
    }

    @Test
    void totalUnreadFor_ShouldReturnUnreadCount() {
        // given
        when(roomRepository.findAllRoomsForUserSorted("testuser"))
                .thenReturn(List.of(testRoom));
        when(messageRepository.countByRoomIdAndSenderNot(1L, "testuser"))
                .thenReturn(5L);

        // when
        long result = chatService.totalUnreadFor("testuser");

        // then
        assertThat(result).isEqualTo(5L);
    }

    @Test
    void validateRoomId_ShouldThrowWhenNull() {
        // when & then
        assertThatThrownBy(() -> chatService.openById(null, "testuser"))
                .isInstanceOf(InvalidChatParameterException.class);
    }

    @Test
    void validateRoomId_ShouldThrowWhenNegative() {
        // when & then
        assertThatThrownBy(() -> chatService.openById(-1L, "testuser"))
                .isInstanceOf(InvalidChatParameterException.class);
    }

    @Test
    void validatePetId_ShouldThrowWhenNull() {
        // when & then
        assertThatThrownBy(() -> chatService.openForUser(null, "testuser"))
                .isInstanceOf(InvalidChatParameterException.class);
    }

    @Test
    void validateLogin_ShouldThrowWhenEmpty() {
        // when & then
        assertThatThrownBy(() -> chatService.myRooms(""))
                .isInstanceOf(InvalidChatParameterException.class);

        assertThatThrownBy(() -> chatService.myRooms("   "))
                .isInstanceOf(InvalidChatParameterException.class);
    }
}
