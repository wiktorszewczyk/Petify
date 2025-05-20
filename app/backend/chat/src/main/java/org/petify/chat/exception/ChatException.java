package org.petify.chat.exception;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.web.ErrorResponse;

import java.time.Instant;

public abstract class ChatException extends RuntimeException implements ErrorResponse {

    private final HttpStatusCode status;

    protected ChatException(HttpStatus status, String detail) {
        super(detail);
        this.status = status;
    }

    @Override
    public HttpStatusCode getStatusCode() {
        return status;
    }

    @Override
    public ProblemDetail getBody() {
        ProblemDetail pd = ProblemDetail.forStatusAndDetail(status, getMessage());
        pd.setTitle(status.toString());
        pd.setProperty("timestamp", Instant.now());
        pd.setDetail(getMessage());
        return pd;
    }
}
