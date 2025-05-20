package org.petify.chat.exception;

import org.springframework.http.HttpStatus;

public class ForbiddenOperationException extends ChatException {
    public ForbiddenOperationException(String message) {
        super(HttpStatus.FORBIDDEN, message);
    }
}
