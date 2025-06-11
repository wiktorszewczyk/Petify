package org.petify.feed.specification;

import org.petify.feed.model.FeedItem;

import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

public class FeedItemSpecification {
    public static <T extends FeedItem> Specification<T> hasContent(String content) {
        return (root, query, criteriaBuilder) -> {
            if (content == null || content.isEmpty()) {
                return criteriaBuilder.conjunction();
            }
            String[] words = content.toLowerCase().split("\\s+");
            List<Predicate> wordPredicates = new ArrayList<>();

            for (String word : words) {
                Predicate wordPredicate = criteriaBuilder.or(
                        criteriaBuilder.like(criteriaBuilder.lower(root.get("title")), "%" + word + "%"),
                        criteriaBuilder.like(criteriaBuilder.lower(root.get("shortDescription")), "%" + word + "%"),
                        criteriaBuilder.like(criteriaBuilder.lower(root.get("longDescription")), "%" + word + "%")
                );
                wordPredicates.add(wordPredicate);
            }
            return criteriaBuilder.and(wordPredicates.toArray(new Predicate[0]));
        };
    }
}
