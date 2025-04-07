package org.petify.backend.security.models;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class RegistrationDTO {
    private String username;
    private String password;

    public RegistrationDTO() {
        super();
    }

    public RegistrationDTO(String username, String password) {
        super();
        this.username = username;
        this.password = password;
    }

    @Override
    public String toString() {
        return "Registration info: username: " + this.username + " password: " + this.password;
    }
}
