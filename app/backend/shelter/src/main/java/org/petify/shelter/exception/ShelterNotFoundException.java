package org.petify.shelter.exception;

public class ShelterNotFoundException extends RuntimeException {
    public ShelterNotFoundException(Long shelterId) {
        super("Shelter with ID " + shelterId + " not found.");
    }
}
