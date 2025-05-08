package org.petify.shelter.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.*;
import org.apache.commons.lang3.builder.EqualsBuilder;
import org.apache.commons.lang3.builder.HashCodeBuilder;
import org.apache.commons.lang3.builder.ToStringBuilder;
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

    @OneToMany(mappedBy = "pet", cascade = CascadeType.ALL, orphanRemoval = true)
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

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;

        if (!(o instanceof Pet pet)) return false;

        return new EqualsBuilder().append(isVaccinated(), pet.isVaccinated()).append(isUrgent(), pet.isUrgent()).append(isSterilized(), pet.isSterilized()).append(isKidFriendly(), pet.isKidFriendly()).append(isArchived(), pet.isArchived()).append(getId(), pet.getId()).append(getName(), pet.getName()).append(getType(), pet.getType()).append(getBreed(), pet.getBreed()).append(getAge(), pet.getAge()).append(getGender(), pet.getGender()).append(getDescription(), pet.getDescription()).append(getShelter(), pet.getShelter()).isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37).append(getId()).append(getName()).append(getType()).append(getBreed()).append(getAge()).append(getGender()).append(isVaccinated()).append(isUrgent()).append(isSterilized()).append(isKidFriendly()).append(isArchived()).append(getDescription()).append(getShelter()).toHashCode();
    }

    @Override
    public String toString() {
        return new ToStringBuilder(this)
                .append("adoptions", adoptions)
                .append("shelter", shelter)
                .append("description", description)
                .append("archived", archived)
                .append("kidFriendly", kidFriendly)
                .append("sterilized", sterilized)
                .append("urgent", urgent)
                .append("vaccinated", vaccinated)
                .append("gender", gender)
                .append("age", age)
                .append("breed", breed)
                .append("type", type)
                .append("name", name)
                .toString();
    }
}