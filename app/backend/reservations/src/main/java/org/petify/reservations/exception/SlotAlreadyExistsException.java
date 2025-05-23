package org.petify.reservations.exception;

public class SlotAlreadyExistsException extends RuntimeException {
    public SlotAlreadyExistsException(String message) {
        super(message);
    }
}