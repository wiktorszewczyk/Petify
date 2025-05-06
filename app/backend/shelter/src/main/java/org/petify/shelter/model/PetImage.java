package org.petify.shelter.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "pet_images")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class PetImage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "image_name")
    private String imageName;

    @Column(name = "image_extension")
    private String imageType;

    @Lob
    @Column(name = "image_data", nullable = false)
    private byte[] imageData;

    @ManyToOne
    @JoinColumn(name = "pet_id", nullable = false)
    private Pet pet;
}
