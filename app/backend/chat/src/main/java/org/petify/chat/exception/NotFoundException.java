package org.petify.chat.exception;

import org.springframework.http.HttpStatus;

public class NotFoundException extends ChatException {
    public NotFoundException(String message) {
        super(HttpStatus.NOT_FOUND, message);
    }
}
