package org.petify.image.exception;

public class MaxImagesReachedException extends RuntimeException {
    public MaxImagesReachedException(Long id, String entityType) {
        super("Entity with entityType " + entityType + " and id " + id + " reached max images (5).");
    }
}
