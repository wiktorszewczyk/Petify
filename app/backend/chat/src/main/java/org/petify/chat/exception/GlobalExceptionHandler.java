package org.petify.chat.exception;

import org.springframework.http.*;
import org.springframework.validation.FieldError;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.time.Instant;
import java.util.Map;

@ControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex,
            HttpHeaders headers,
            HttpStatusCode status,
            WebRequest request) {

        ProblemDetail pd = ProblemDetail.forStatusAndDetail(status,
                "Validation failed for request.");
        pd.setTitle("Validation error");
        pd.setProperty("errors", ex.getBindingResult().getFieldErrors().stream()
                .map(this::toMap).toList());
        pd.setProperty("timestamp", Instant.now());
        pd.setDetail(ex.getMessage());

        return super.handleExceptionInternal(ex, pd, headers, status, request);
    }

    private Map<String, String> toMap(FieldError fe) {
        return Map.of("field", fe.getField(), "message", fe.getDefaultMessage());
    }

    @ExceptionHandler(Exception.class)
    public ProblemDetail handleAnythingElse(Exception ex) {

        if (ex instanceof ErrorResponse er) {
            return er.getBody();
        }

        ProblemDetail pd = ProblemDetail.forStatusAndDetail(
                HttpStatus.INTERNAL_SERVER_ERROR,
                ex.getMessage() != null ? ex.getMessage() : "Unexpected error");

        pd.setTitle("Internal Server Error");
        pd.setProperty("timestamp", Instant.now());
        pd.setDetail(ex.getMessage());
        return pd;
    }
}
