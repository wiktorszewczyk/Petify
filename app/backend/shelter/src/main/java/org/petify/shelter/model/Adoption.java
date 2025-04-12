package org.petify.shelter.model;

import jakarta.persistence.*;
import lombok.*;
import org.apache.commons.lang3.builder.EqualsBuilder;
import org.apache.commons.lang3.builder.HashCodeBuilder;
import org.apache.commons.lang3.builder.ToStringBuilder;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "adoption_forms")
public class Adoption {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(nullable = false)
    private Integer userId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pet_id", nullable = false)
    private Pet pet;

    @Enumerated(EnumType.STRING)
    @Column(name = "adoption_status", nullable = false)
    private AdoptionStatus adoptionStatus = AdoptionStatus.PENDING;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;

        if (!(o instanceof Adoption that)) return false;

        return new EqualsBuilder().append(getId(), that.getId()).append(getUserId(), that.getUserId()).append(getPet(), that.getPet()).append(getAdoptionStatus(), that.getAdoptionStatus()).isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37).append(getId()).append(getUserId()).append(getPet()).append(getAdoptionStatus()).toHashCode();
    }

    @Override
    public String toString() {
        return new ToStringBuilder(this)
                .append("id", id)
                .append("userId", userId)
                .append("pet", pet)
                .append("adoptionStatus", adoptionStatus)
                .toString();
    }
}