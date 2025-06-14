package org.petify.shelter.util;

public class ImageUrlConverter {
    public static String toFullImageUrl(String filename) {
        if (filename == null || filename.isEmpty()) {
            return null;
        }
        return "https://petify.fra1.cdn.digitaloceanspaces.com/" + filename;
    }
}
