package org.petify.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LoginRequestDTO {
    @NotBlank(message = "Login identifier is required")
    private String loginIdentifier; // Can be either email or phone

    @NotBlank(message = "Password is required")
    private String password;

    public LoginRequestDTO() {
        super();
    }

    public LoginRequestDTO(String loginIdentifier, String password) {
        super();
        this.loginIdentifier = loginIdentifier;
        this.password = password;
    }
}
