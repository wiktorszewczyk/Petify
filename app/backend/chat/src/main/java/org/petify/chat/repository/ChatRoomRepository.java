// ChatRoomRepository.java
package org.petify.chat.repository;

import org.petify.chat.model.ChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {
    Optional<ChatRoom> findByPetIdAndUserName(Long petId, String userName);

    List<ChatRoom> findAllByPetIdAndShelterName(Long petId, String shelterName);

    List<ChatRoom> findAllByUserNameOrShelterName(String userName, String shelterName);
}
