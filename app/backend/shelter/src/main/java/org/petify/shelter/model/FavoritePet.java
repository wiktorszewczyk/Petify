package org.petify.shelter.model;

import org.petify.shelter.enums.MatchType;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.apache.commons.lang3.builder.EqualsBuilder;
import org.apache.commons.lang3.builder.HashCodeBuilder;
import org.apache.commons.lang3.builder.ToStringBuilder;

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

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private MatchType status;

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }

        if (!(o instanceof FavoritePet that)) {
            return false;
        }

        return new EqualsBuilder().append(getId(), that.getId()).append(getUsername(),
                that.getUsername()).append(getPet(), that.getPet()).append(getStatus(), that.getStatus()).isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37).append(getId())
                .append(getUsername()).append(getPet()).append(getStatus()).toHashCode();
    }

    @Override
    public String toString() {
        return new ToStringBuilder(this)
                .append("id", id)
                .append("username", username)
                .append("pet", pet)
                .append("status", status)
                .toString();
    }
}
