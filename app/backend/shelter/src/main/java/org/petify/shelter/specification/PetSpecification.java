package org.petify.shelter.specification;

import org.petify.shelter.enums.PetType;
import org.petify.shelter.model.Pet;

import org.springframework.data.jpa.domain.Specification;

import java.util.List;

public class PetSpecification {

    public static Specification<Pet> hasVaccinated(Boolean vaccinated) {
        return (root, query, cb) -> vaccinated == null ? null : cb.equal(root.get("vaccinated"), vaccinated);
    }

    public static Specification<Pet> isUrgent(Boolean urgent) {
        return (root, query, cb) -> urgent == null ? null : cb.equal(root.get("urgent"), urgent);
    }

    public static Specification<Pet> isSterilized(Boolean sterilized) {
        return (root, query, cb) -> sterilized == null ? null : cb.equal(root.get("sterilized"), sterilized);
    }

    public static Specification<Pet> isKidFriendly(Boolean kidFriendly) {
        return (root, query, cb) -> kidFriendly == null ? null : cb.equal(root.get("kidFriendly"), kidFriendly);
    }

    public static Specification<Pet> ageBetween(Integer minAge, Integer maxAge) {
        return (root, query, cb) -> {
            if (minAge != null && maxAge != null) {
                return cb.between(root.get("age"), minAge, maxAge);
            } else if (minAge != null) {
                return cb.greaterThanOrEqualTo(root.get("age"), minAge);
            } else if (maxAge != null) {
                return cb.lessThanOrEqualTo(root.get("age"), maxAge);
            } else {
                return null;
            }
        };
    }

    public static Specification<Pet> hasType(PetType type) {
        return (root, query, cb) -> type == null ? null : cb.equal(root.get("type"), type);
    }

    public static Specification<Pet> isNotArchived() {
        return (root, query, cb) -> cb.isFalse(root.get("archived"));
    }

    public static Specification<Pet> hasActiveShelter() {
        return (root, query, cb) -> cb.isTrue(root.get("shelter").get("isActive"));
    }

    public static Specification<Pet> notInFavorites(List<Long> favoriteIds) {
        return (root, query, cb) -> favoriteIds.isEmpty() ? null : cb.not(root.get("id").in(favoriteIds));
    }
<<<<<<< HEAD
=======

    public static Specification<Pet> idGreaterThan(Long id) {
        return (root, query, cb) -> cb.greaterThan(root.get("id"), id);
    }
>>>>>>> origin/main
}
