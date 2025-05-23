package org.petify.reservations.exception;

public class PetServiceUnavailableException extends RuntimeException {
    public PetServiceUnavailableException(String message) {
        super(message);
    }
}