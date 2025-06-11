package org.petify.feed.exception;

public class MaxEventCapacityReachedException extends RuntimeException {
    public MaxEventCapacityReachedException(Long eventId, int capacity) {
        super("Cannot join event. Event with id " + eventId + " has already reached its maximum capacity (" + capacity + ")");
    }
}
