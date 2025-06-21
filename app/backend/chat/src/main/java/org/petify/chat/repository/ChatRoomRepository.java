package org.petify.chat.repository;

import org.petify.chat.model.ChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query; // Upewnij się, że ten import jest dodany
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {

    Optional<ChatRoom> findByPetIdAndUserName(Long petId, String userName);

    @Query("SELECT r FROM ChatRoom r " +
            "WHERE r.userName = :login OR r.shelterName = :login " +
            "ORDER BY r.lastMessageTimestamp DESC NULLS LAST")
    List<ChatRoom> findAllRoomsForUserSorted(String login);

}