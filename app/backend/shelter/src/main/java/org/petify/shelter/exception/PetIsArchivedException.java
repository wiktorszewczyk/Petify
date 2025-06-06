package org.petify.shelter.exception;

public class PetIsArchivedException extends RuntimeException {
    public PetIsArchivedException(Long id) {
        super("Pet with id: " + id + " is archived!");
    }
}
