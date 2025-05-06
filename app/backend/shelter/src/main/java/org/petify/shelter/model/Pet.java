package org.petify.shelter.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.*;
import org.petify.shelter.enums.Gender;
import org.petify.shelter.enums.PetType;

import java.util.List;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "pets")
public class Pet {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(name = "name", nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false)
    private PetType type;

    @Column(name = "breed")
    private String breed;

    @PositiveOrZero(message = "Age cannot be negative!")
    @Column(name = "age", nullable = false)
    private Integer age;

    @Enumerated(EnumType.STRING)
    @Column(name = "gender")
    private Gender gender;

    @Column(name = "is_vaccinated", nullable = false)
    private boolean vaccinated;

    @Column(name = "is_urgent", nullable = false)
    private boolean urgent;

    @Column(name = "is_sterilized", nullable = false)
    private boolean sterilized;

    @Column(name = "is_kid_friendly", nullable = false)
    private boolean kidFriendly;

    @Column(name = "is_archived")
    private boolean archived = false;

    @Column(name = "description")
    private String description;

    @ManyToOne
    @JoinColumn(name = "shelter_id", nullable = false)
    private Shelter shelter;

    @OneToMany(mappedBy = "pet")
    private List<Adoption> adoptions;

    @Column(name = "image_name")
    private String imageName;

    @Column(name = "image_extension")
    private String imageType;

    @Lob
    @Column(name = "image_data")
    private byte[] imageData;

    @OneToMany(mappedBy = "pet", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<PetImage> images;

    @OneToMany(mappedBy = "pet", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<FavoritePet> favoritePets;

    public Pet(Shelter shelter, String description, boolean kidFriendly, boolean sterilized,
               boolean urgent, boolean vaccinated, Gender gender, Integer age, String breed, PetType type, String name) {
        this.shelter = shelter;
        this.description = description;
        this.kidFriendly = kidFriendly;
        this.sterilized = sterilized;
        this.urgent = urgent;
        this.vaccinated = vaccinated;
        this.gender = gender;
        this.age = age;
        this.breed = breed;
        this.type = type;
        this.name = name;
    }
}