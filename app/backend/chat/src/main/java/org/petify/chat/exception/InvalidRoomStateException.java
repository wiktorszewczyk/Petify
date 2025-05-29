package org.petify.chat.exception;

public class InvalidRoomStateException extends RuntimeException {
    public InvalidRoomStateException(String message) {
        super(message);
    }
}
