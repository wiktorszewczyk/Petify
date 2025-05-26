package org.petify.shelter.exception;

public class AdoptionFormNotFoundException extends RuntimeException {
    public AdoptionFormNotFoundException(Long id) {
        super("Form with id: " + id + " not found.");
    }
}
