package org.petify.chat.exception;

import org.springframework.http.HttpStatus;

public class ConflictException extends ChatException {
    public ConflictException(String message) {
        super(HttpStatus.CONFLICT, message);
    }
}
