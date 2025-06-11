package org.petify.feed.repository;

import org.petify.feed.model.Post;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface PostRepository extends JpaRepository<Post, Long>, JpaSpecificationExecutor<Post> {
    @Query("SELECT p FROM Post p "
            + "JOIN FeedItem f ON p.id = f.id "
            + "WHERE f.createdAt >= :fromDate "
            + "ORDER BY f.createdAt DESC")
    List<Post> findRecentPosts(@Param("fromDate") LocalDateTime fromDate);

    List<Post> findAllByShelterId(Long shelterId);
}
