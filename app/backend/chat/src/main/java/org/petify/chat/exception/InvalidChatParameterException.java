package org.petify.chat.exception;

public class InvalidChatParameterException extends RuntimeException {
    public InvalidChatParameterException(String message) {
        super(message);
    }
}