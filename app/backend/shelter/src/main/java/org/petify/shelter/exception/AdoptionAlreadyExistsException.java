package org.petify.shelter.exception;

public class AdoptionAlreadyExistsException extends RuntimeException {
    public AdoptionAlreadyExistsException(Long petId, String username) {
        super(String.format("User '%s' already has a pending adoption request for pet with ID %d", username, petId));
    }
}
