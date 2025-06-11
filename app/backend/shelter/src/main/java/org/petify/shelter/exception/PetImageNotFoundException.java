package org.petify.shelter.exception;

public class PetImageNotFoundException extends RuntimeException {
    public PetImageNotFoundException(Long imageId) {
        super("Pet image with id " + imageId + " not found");
    }
}
