package org.petify.shelter.exception;

public class ShelterIsNotActiveException extends RuntimeException {
    public ShelterIsNotActiveException(Long shelterId) {
        super("Shelter with id: " + shelterId + " is not active");
    }
    public ShelterIsNotActiveException() {
        super("Shelter is not active.");
    }
}
