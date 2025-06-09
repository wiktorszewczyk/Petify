package org.petify.image.exception;

public class MaxImagesReachedException extends RuntimeException {
    public MaxImagesReachedException(Long id) {
        super("Entity with id " + id + " reached max images (5).");
    }
}
