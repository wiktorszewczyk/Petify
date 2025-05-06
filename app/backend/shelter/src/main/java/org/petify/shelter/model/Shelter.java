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
}