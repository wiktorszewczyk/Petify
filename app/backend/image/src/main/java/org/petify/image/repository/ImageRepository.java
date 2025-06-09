
package org.petify.image.repository;

import org.petify.image.model.Image;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ImageRepository extends JpaRepository<Image, Long> {

    List<Image> findAllByEntityId(Long entityId);

    int countByEntityId(Long entityId);
}
