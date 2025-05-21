package org.petify.chat.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(of = {"petId", "userName"})
@ToString
@Entity
@Table(uniqueConstraints = @UniqueConstraint(columnNames = {"pet_id", "userName"}))
public class ChatRoom {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Column(nullable = false)
    private String userName;

    @Column(nullable = false)
    private String shelterName;

    @Column(nullable = false)
    private boolean userVisible = true;

    @Column(nullable = false)
    private boolean shelterVisible = true;

    @Column(name = "user_hidden_at")
    private LocalDateTime userHiddenAt;

    @Column(name = "shelter_hidden_at")
    private LocalDateTime shelterHiddenAt;

    @Column(name = "user_last_read_at")
    private LocalDateTime userLastReadAt;

    @Column(name = "shelter_last_read_at")
    private LocalDateTime shelterLastReadAt;
}
