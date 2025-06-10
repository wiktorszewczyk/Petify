
package org.petify.image.repository;

import org.petify.image.model.Image;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ImageRepository extends JpaRepository<Image, Long> {

    Optional<List<Image>> findAllByEntityIdAndEntityType(Long entityId, String entityType);

    int countByEntityIdAndEntityType(Long entityId, String entityType);
}
