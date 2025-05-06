package org.petify.shelter.model;

import jakarta.persistence.*;
import lombok.*;
import org.apache.commons.lang3.builder.*;

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

    @Column(name = "owner_username", unique = true, nullable = false)
    private String ownerUsername;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "description")
    private String description;

    @Column(name = "address")
    private String address;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    @Column(name = "phone_number")
    private String phoneNumber;

    @OneToMany(mappedBy = "shelter")
    private List<Pet> pets;

    public Shelter(String ownerUsername, String name, String description, String address, Double latitude, Double longitude, String phoneNumber) {
        this.ownerUsername = ownerUsername;
        this.name = name;
        this.description = description;
        this.address = address;
        this.latitude = latitude;
        this.longitude = longitude;
        this.phoneNumber = phoneNumber;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;

        if (!(o instanceof Shelter shelter)) return false;

        return new EqualsBuilder().append(getId(), shelter.getId()).append(getOwnerUsername(), shelter.getOwnerUsername()).append(getName(), shelter.getName()).append(getDescription(), shelter.getDescription()).append(getAddress(), shelter.getAddress()).append(getLatitude(), shelter.getLatitude()).append(getLongitude(), shelter.getLongitude()).append(getPhoneNumber(), shelter.getPhoneNumber()).isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37).append(getId()).append(getOwnerUsername()).append(getName()).append(getDescription()).append(getAddress()).append(getLatitude()).append(getLongitude()).append(getPhoneNumber()).toHashCode();
    }

    @Override
    public String toString() {
        return new ToStringBuilder(this)
                .append("id", id)
                .append("ownerUsername", ownerUsername)
                .append("name", name)
                .append("description", description)
                .append("address", address)
                .append("latitude", latitude)
                .append("longitude", longitude)
                .append("phoneNumber", phoneNumber)
                .append("pets", pets)
                .toString();
    }
}