package org.petify.chat.repository;

import org.petify.chat.model.ChatMessage;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {

    Page<ChatMessage> findByRoomIdOrderByTimestampDesc(Long roomId, Pageable pageable);

    Page<ChatMessage> findByRoomIdAndTimestampAfterOrderByTimestampDesc(
            Long roomId, LocalDateTime after, Pageable pageable);

    long countByRoomIdAndTimestampAfterAndSenderNot(
            Long roomId,
            LocalDateTime after,
            String senderToExclude);

    long countByRoomIdAndSenderNot(Long roomId, String senderToExclude);

    void deleteByRoomId(Long roomId);
}
