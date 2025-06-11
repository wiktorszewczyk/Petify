package org.petify.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@Getter
@Setter
public class RegistrationDTO {
    private String username; // generated based on email or phone

    @NotBlank(message = "First name is required")
    private String firstName;

    @NotBlank(message = "Last name is required")
    private String lastName;

    @Past(message = "Birth date must be in the past")
    private LocalDate birthDate;

    @NotBlank(message = "Gender is required")
    private String gender;

    @Pattern(regexp = "^\\+?[0-9]{9,15}$", message = "Invalid phone number format")
    private String phoneNumber;

    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Password is required")
    private String password;

    private Long shelterId;

    private boolean applyAsVolunteer;

    public RegistrationDTO() {
        super();
    }

    public RegistrationDTO(String firstName, String lastName, LocalDate birthDate,
                           String gender, String phoneNumber, String email, String password) {
        super();
        this.firstName = firstName;
        this.lastName = lastName;
        this.birthDate = birthDate;
        this.gender = gender;
        this.phoneNumber = phoneNumber;
        this.email = email;
        this.password = password;
    }

    @Override
    public String toString() {
        return "Registration info: firstName: " + this.firstName
                + ", lastName: " + this.lastName
                + ", email: " + this.email
                + ", phoneNumber: " + this.phoneNumber;
    }
}
