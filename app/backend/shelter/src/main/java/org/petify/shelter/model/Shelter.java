package org.petify.shelter.model;

import jakarta.persistence.*;
import lombok.*;
import org.apache.commons.lang3.builder.EqualsBuilder;
import org.apache.commons.lang3.builder.HashCodeBuilder;
import org.apache.commons.lang3.builder.ToStringBuilder;

import java.util.List;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "shelters")
public class Shelter {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(name = "owner_id", nullable = false)
    private Integer ownerId;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "description")
    private String description;

    @Column(name = "address")
    private String address;

    @Column(name = "phone_number")
    private String phoneNumber;

    @OneToMany(mappedBy = "shelter")
    private List<Pet> pets;

    public Shelter(Integer ownerId, String name, String description, String address, String phoneNumber) {
        this.ownerId = ownerId;
        this.name = name;
        this.description = description;
        this.address = address;
        this.phoneNumber = phoneNumber;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;

        if (!(o instanceof Shelter shelter)) return false;

        return new EqualsBuilder().append(getId(), shelter.getId()).append(getOwnerId(), shelter.getOwnerId()).append(getName(), shelter.getName()).append(getDescription(), shelter.getDescription()).append(getAddress(), shelter.getAddress()).append(getPhoneNumber(), shelter.getPhoneNumber()).isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37).append(getId()).append(getOwnerId()).append(getName()).append(getDescription()).append(getAddress()).append(getPhoneNumber()).toHashCode();
    }

    @Override
    public String toString() {
        return new ToStringBuilder(this)
                .append("id", id)
                .append("ownerId", ownerId)
                .append("name", name)
                .append("description", description)
                .append("address", address)
                .append("phoneNumber", phoneNumber)
                .toString();
    }
}