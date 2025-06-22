package org.petify.feed.service;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.feed.dto.PostRequest;
import org.petify.feed.dto.PostResponse;
import org.petify.feed.exception.FeedItemNotFoundException;
import org.petify.feed.mapper.PostMapper;
import org.petify.feed.model.Post;
import org.petify.feed.repository.PostRepository;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PostServiceTest {

    @Mock
    private PostRepository postRepository;

    @Mock
    private PostMapper postMapper;

    @InjectMocks
    private PostService postService;

    @Test
    void getPostById_WhenExists_ShouldReturnPost() {
        // Arrange
        Long postId = 1L;
        Post post = new Post();
        PostResponse response = new PostResponse(postId, 1L, "Test", "Desc", 
            null, null, null, List.of(), LocalDateTime.now(), LocalDateTime.now());
        
        when(postRepository.findById(postId)).thenReturn(Optional.of(post));
        when(postMapper.toDto(post)).thenReturn(response);

        // Act
        PostResponse result = postService.getPostById(postId);

        // Assert
        assertEquals(response, result);
    }

    @Test
    void createPost_ShouldSaveAndReturnPost() {
        // Arrange
        Long shelterId = 1L;
        PostRequest request = new PostRequest("Test", "Desc", null, null, null, List.of(1L, 2L));
        Post post = new Post();
        PostResponse response = new PostResponse(1L, shelterId, "Test", "Desc", 
            null, null, null, List.of(1L, 2L), LocalDateTime.now(), LocalDateTime.now());
        
        when(postMapper.toEntity(request)).thenReturn(post);
        when(postRepository.save(post)).thenReturn(post);
        when(postMapper.toDto(post)).thenReturn(response);

        // Act
        PostResponse result = postService.createPost(shelterId, request);

        // Assert
        assertEquals(response, result);
        assertEquals(shelterId, post.getShelterId());
    }

    @Test
    void updatePost_WhenExists_ShouldUpdateAndReturnPost() {
        // Arrange
        Long postId = 1L;
        PostRequest request = new PostRequest("Updated", "New Desc", 1L, "Long Desc", 2L, List.of(3L, 4L));
        Post existingPost = new Post();
        PostResponse response = new PostResponse(postId, 1L, "Updated", "New Desc", 
            1L, "Long Desc", 2L, List.of(3L, 4L), LocalDateTime.now(), LocalDateTime.now());
        
        when(postRepository.findById(postId)).thenReturn(Optional.of(existingPost));
        when(postRepository.save(existingPost)).thenReturn(existingPost);
        when(postMapper.toDto(existingPost)).thenReturn(response);

        // Act
        PostResponse result = postService.updatePost(postId, request);

        // Assert
        assertEquals(response, result);
        assertEquals("Updated", existingPost.getTitle());
        assertEquals("New Desc", existingPost.getShortDescription());
        assertEquals(List.of(3L, 4L), existingPost.getImageIds());
    }

    @Test
    void getRecentPosts_ShouldReturnFilteredPosts() {
        // Arrange
        int days = 7;
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime dateDaysAgo = now.minusDays(days);
        Post post1 = new Post();
        post1.setCreatedAt(now.minusDays(3));
        Post post2 = new Post();
        post2.setCreatedAt(now.minusDays(8)); // Should be filtered out
        
        // Use argument matcher instead of exact timestamp
        when(postRepository.findRecentPosts(any(LocalDateTime.class))).thenReturn(List.of(post1));
        when(postMapper.toDto(post1)).thenReturn(new PostResponse(1L, 1L, "Test", "Desc", 
            null, null, null, List.of(), now, now));

        // Act
        List<PostResponse> result = postService.getAllRecentPosts(days);

        // Assert
        assertEquals(1, result.size());
    }

    @Test
    void deletePost_WhenExists_ShouldDelete() {
        // Arrange
        Long postId = 1L;
        
        when(postRepository.existsById(postId)).thenReturn(true);

        // Act
        postService.deletePost(postId);

        // Assert
        verify(postRepository).deleteById(postId);
    }
}
