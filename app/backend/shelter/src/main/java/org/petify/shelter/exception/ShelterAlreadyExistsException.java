package org.petify.shelter.exception;

public class ShelterAlreadyExistsException extends RuntimeException {
    public ShelterAlreadyExistsException(String username) {
        super("Shelter already exists for user: " + username);
    }
}
