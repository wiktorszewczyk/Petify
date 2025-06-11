package org.petify.feed.controller;

import org.petify.feed.dto.PostRequest;
import org.petify.feed.dto.PostResponse;
import org.petify.feed.service.PostService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.security.oauth2.resource.OAuth2ResourceServerProperties.Jwt;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RequiredArgsConstructor
@RestController
@RequestMapping("/posts")
public class PostController {
    private final PostService postService;

    @GetMapping("/{postId}")
    public ResponseEntity<PostResponse> getPostById(@PathVariable Long postId) {
        PostResponse post = postService.getPostById(postId);
        return ResponseEntity.ok(post);
    }

    @GetMapping("/shelter/{shelterId}/posts")
    public ResponseEntity<List<PostResponse>> getPostsByShelterId(@PathVariable Long shelterId) {
        List<PostResponse> posts = postService.getPostsByShelterId(shelterId);
        return ResponseEntity.ok(posts);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @PostMapping("/shelter/{shelterId}/posts")
    public ResponseEntity<PostResponse> createPost(
            @PathVariable Long shelterId,
            @Valid @RequestBody PostRequest postRequest,
            @AuthenticationPrincipal Jwt jwt) {
        if (postRequest == null) {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        }
        PostResponse post = postService.createPost(shelterId, postRequest);
        return ResponseEntity.status(HttpStatus.CREATED).body(post);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @PutMapping("/{postId}")
    public ResponseEntity<PostResponse> updatePost(
            @PathVariable Long postId,
            @Valid @RequestBody PostRequest postRequest,
            @AuthenticationPrincipal Jwt jwt) {
        if (postRequest == null) {
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        }
        PostResponse updatedPost = postService.updatePost(postId, postRequest);
        return ResponseEntity.ok(updatedPost);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'SHELTER')")
    @DeleteMapping("/{postId}")
    public ResponseEntity<?> deletePost(
            @PathVariable Long postId,
            @AuthenticationPrincipal Jwt jwt) {
        postService.deletePost(postId);
        return new ResponseEntity<>(HttpStatus.NO_CONTENT);
    }
}
