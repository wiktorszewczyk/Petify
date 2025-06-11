package org.petify.image.exception;

public class ImageNotFoundException extends RuntimeException {
    public ImageNotFoundException(Long imageId) {
        super("Image with id " + imageId + " not found");
    }
}
