package org.petify.backend.dto;

import org.petify.backend.models.ApplicationUser;

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

    public ApplicationUser getUser() {
        return this.user;
    }

    public void setUser(ApplicationUser user) {
        this.user = user;
    }

    public String getJwt() {
        return this.jwt;
    }

    public void setJwt(String jwt) {
        this.jwt = jwt;
    }

    public String getErrorMessage() {
        return this.errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }
}