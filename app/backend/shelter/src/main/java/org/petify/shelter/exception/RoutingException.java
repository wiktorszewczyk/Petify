package org.petify.shelter.exception;

public class RoutingException extends Exception {

    public RoutingException(String message) {
        super(message);
    }

    public RoutingException(String message, Throwable cause) {
        super(message, cause);
    }
}
