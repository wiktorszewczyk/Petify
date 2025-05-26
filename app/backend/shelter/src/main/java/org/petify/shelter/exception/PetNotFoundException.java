package org.petify.shelter.exception;

public class PetNotFoundException extends RuntimeException {
    public PetNotFoundException(Long id) {
        super("Pet with ID " + id + " not found.");
    }
}
