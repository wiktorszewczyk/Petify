package org.petify.feed.exception;

public class FeedItemNotFoundException extends RuntimeException {
    public FeedItemNotFoundException(Long feedItemId, String itemType) {
        super(itemType + " with id " + feedItemId + " not found");
    }

    public FeedItemNotFoundException(String feedItemId, String itemType) {
        super(itemType + " with id " + feedItemId + " not found");
    }
}
