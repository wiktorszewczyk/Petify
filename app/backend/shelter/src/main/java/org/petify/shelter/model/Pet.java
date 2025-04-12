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

    @Column(name = "age")
    private Integer age;

    @Column(name = "is_archived")
    private boolean archived = false;

    @Column(name = "description")
    private String description;

    @ManyToOne
    @JoinColumn(name = "shelter_id", nullable = false)
    private Shelter shelter;

    @OneToMany(mappedBy = "pet")
    private List<AdoptionForm> adoptionForms;

    @Column(name = "image_name")
    private String imageName;

    @Column(name = "image_extension")
    private String imageType;

    @Lob
    @Column(name = "image_data")
    private byte[] imageData;

    public Pet(String name, PetType type, String breed, Integer age, String description, Shelter shelter) {
        this.name = name;
        this.type = type;
        this.breed = breed;
        this.age = age;
        this.description = description;
        this.shelter = shelter;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;

        if (!(o instanceof Pet pet)) return false;

        return new EqualsBuilder().append(isArchived(), pet.isArchived()).append(getId(), pet.getId()).append(getName(), pet.getName()).append(getType(), pet.getType()).append(getBreed(), pet.getBreed()).append(getAge(), pet.getAge()).append(getDescription(), pet.getDescription()).isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37).append(getId()).append(getName()).append(getType()).append(getBreed()).append(getAge()).append(isArchived()).append(getDescription()).toHashCode();
    }

    @Override
    public String toString() {
        return new ToStringBuilder(this)
                .append("description", description)
                .append("archived", archived)
                .append("age", age)
                .append("breed", breed)
                .append("type", type)
                .append("name", name)
                .append("id", id)
                .toString();
    }
}