package org.petify.chat.model;

import jakarta.persistence.*;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(of = {"petId", "userName"})
@ToString
@Entity
@Table(uniqueConstraints = {
        @UniqueConstraint(columnNames = {"pet_id", "userName"})
})
public class ChatRoom {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "pet_id", nullable = false)
    private Long petId;

    @Column(name = "userName", nullable = false)
    private String userName;

    @Column(name = "shelterName", nullable = false)
    private String shelterName;
}
