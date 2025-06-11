package org.petify.feed.exception;

public class AlreadyParticipatingException extends RuntimeException {
    public AlreadyParticipatingException(Long eventId, String username) {
        super("User " + username + " is already participating in event with id " + eventId);
    }
}
