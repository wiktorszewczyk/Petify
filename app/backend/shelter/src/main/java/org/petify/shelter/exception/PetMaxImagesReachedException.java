package org.petify.shelter.exception;

public class PetMaxImagesReachedException extends RuntimeException {
    public PetMaxImagesReachedException(Long id) {
        super("Pet with id " + id + " reached max images (5).");
    }
}
