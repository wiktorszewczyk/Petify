package org.petify.shelter.model;

import org.petify.shelter.enums.AdoptionStatus;

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
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.apache.commons.lang3.builder.EqualsBuilder;
import org.apache.commons.lang3.builder.HashCodeBuilder;
import org.apache.commons.lang3.builder.ToStringBuilder;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "adoptions")
public class Adoption {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Long id;

    @Column(nullable = false)
    private String username;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "pet_id", nullable = false)
    private Pet pet;

    @Enumerated(EnumType.STRING)
    @Column(name = "adoption_status", nullable = false)
    private AdoptionStatus adoptionStatus = AdoptionStatus.PENDING;

    @Column(name = "motivation_text")
    private String motivationText;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(name = "phone_number")
    private String phoneNumber;

    @Column(name = "address")
    private String address;

    @Column(name = "housing_type")
    private String housingType;

    @Column(name = "is_house_owner")
    private boolean isHouseOwner;

    @Column(name = "has_yard")
    private boolean hasYard;

    @Column(name = "has_other_pets")
    private boolean hasOtherPets;

    @Column(name = "description")
    private String description;

    @CreationTimestamp
    @Column(name = "application_date", nullable = false, updatable = false)
    private LocalDateTime applicationDate;

    public Adoption(String username, Pet pet, AdoptionStatus adoptionStatus, String motivationText, String fullName,
                    String phoneNumber, String address, String housingType, boolean isHouseOwner, boolean hasYard,
                    boolean hasOtherPets, String description) {
        this.username = username;
        this.pet = pet;
        this.adoptionStatus = adoptionStatus;
        this.motivationText = motivationText;
        this.fullName = fullName;
        this.phoneNumber = phoneNumber;
        this.address = address;
        this.housingType = housingType;
        this.isHouseOwner = isHouseOwner;
        this.hasYard = hasYard;
        this.hasOtherPets = hasOtherPets;
        this.description = description;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }

        if (!(o instanceof Adoption adoption)) {
            return false;
        }

        return new EqualsBuilder().append(isHouseOwner(), adoption.isHouseOwner()).append(isHasYard(),
                adoption.isHasYard()).append(isHasOtherPets(), adoption.isHasOtherPets()).append(getId(),
                adoption.getId()).append(getUsername(), adoption.getUsername()).append(getPet(),
                adoption.getPet()).append(getAdoptionStatus(), adoption.getAdoptionStatus()).append(getMotivationText(),
                adoption.getMotivationText()).append(getFullName(), adoption.getFullName()).append(getMotivationText(),
                adoption.getMotivationText()).append(getPhoneNumber(), adoption.getPhoneNumber()).append(getAddress(),
                adoption.getAddress()).append(getHousingType(), adoption.getHousingType()).append(getDescription(),
                adoption.getDescription()).append(getApplicationDate(), adoption.getApplicationDate()).isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37).append(getId()).append(getUsername())
                .append(getPet()).append(getAdoptionStatus()).append(getMotivationText()).append(getFullName())
                .append(getMotivationText()).append(getPhoneNumber()).append(getAddress()).append(getHousingType())
                .append(isHouseOwner()).append(isHasYard()).append(isHasOtherPets())
                .append(getDescription()).append(getApplicationDate()).toHashCode();
    }

    @Override
    public String toString() {
        return new ToStringBuilder(this)
                .append("id", id)
                .append("username", username)
                .append("pet", pet)
                .append("adoptionStatus", adoptionStatus)
                .append("motivationText", motivationText)
                .append("fullName", fullName)
                .append("motivationText", motivationText)
                .append("phoneNumber", phoneNumber)
                .append("address", address)
                .append("housingType", housingType)
                .append("isHouseOwner", isHouseOwner)
                .append("hasYard", hasYard)
                .append("hasOtherPets", hasOtherPets)
                .append("description", description)
                .append("applicationDate", applicationDate)
                .toString();
    }
}
