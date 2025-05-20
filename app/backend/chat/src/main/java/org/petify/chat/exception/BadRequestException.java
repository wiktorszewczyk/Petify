package org.petify.chat.exception;

import org.springframework.http.HttpStatus;

public class BadRequestException extends ChatException {
    public BadRequestException(String message) {
        super(HttpStatus.BAD_REQUEST, message);
    }
}
