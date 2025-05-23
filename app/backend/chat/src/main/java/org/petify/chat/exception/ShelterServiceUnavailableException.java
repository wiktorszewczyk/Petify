package org.petify.chat.exception;

public class ShelterServiceUnavailableException extends RuntimeException {
    public ShelterServiceUnavailableException(String message) {
        super(message);
    }
}