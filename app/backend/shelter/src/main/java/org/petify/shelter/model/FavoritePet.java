package org.petify.shelter.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.apache.commons.lang3.builder.*;

@RequiredArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(
        name = "favorite_pets",
        uniqueConstraints = {
                @UniqueConstraint(columnNames = {"username", "pet_id"})
        }
)
public class FavoritePet {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(name = "username", nullable = false)
    private String username;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pet_id", nullable = false)
    private Pet pet;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof FavoritePet favorite)) return false;

        return new EqualsBuilder()
                .append(getUsername(), favorite.getUsername())
                .append(getPet(), favorite.getPet())
                .isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37)
                .append(getUsername())
                .append(getPet())
                .toHashCode();
    }

    @Override
    public String toString() {
        return new ToStringBuilder(this)
                .append("username", username)
                .append("pet", pet)
                .toString();
    }
}