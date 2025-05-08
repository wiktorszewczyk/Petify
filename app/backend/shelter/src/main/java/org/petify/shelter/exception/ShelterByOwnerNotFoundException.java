package org.petify.shelter.exception;

public class ShelterByOwnerNotFoundException extends RuntimeException {
    public ShelterByOwnerNotFoundException(String username) {
        super("No shelter connected to user: " + username + " found.");
    }
}
