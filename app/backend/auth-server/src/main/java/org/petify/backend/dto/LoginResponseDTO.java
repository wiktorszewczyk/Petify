package org.petify.backend.dto;

import org.petify.backend.models.ApplicationUser;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LoginResponseDTO {
    private ApplicationUser user;
    private String jwt;
    private String errorMessage;

    public LoginResponseDTO() {
        super();
    }

    public LoginResponseDTO(ApplicationUser user, String jwt) {
        this.user = user;
        this.jwt = jwt;
        this.errorMessage = null;
    }

    public LoginResponseDTO(ApplicationUser user, String jwt, String errorMessage) {
        this.user = user;
        this.jwt = jwt;
        this.errorMessage = errorMessage;
    }
}
