package org.petify.feed.service;

import org.petify.feed.dto.PostRequest;
import org.petify.feed.dto.PostResponse;
import org.petify.feed.exception.FeedItemNotFoundException;
import org.petify.feed.mapper.PostMapper;
import org.petify.feed.model.Post;
import org.petify.feed.repository.PostRepository;
import org.petify.feed.specification.FeedItemSpecification;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@RequiredArgsConstructor
@Service
public class PostService {
    private final PostRepository postRepository;
    private final PostMapper postMapper;

    public PostResponse getPostById(Long postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new FeedItemNotFoundException(postId, "Post"));
        return postMapper.toDto(post);
    }

    public List<PostResponse> getPostsByShelterId(Long shelterId) {
        return postRepository.findAllByShelterId(shelterId).stream()
                .map(postMapper::toDto)
                .toList();
    }

    public List<PostResponse> getAllRecentPosts(int days) {
        LocalDateTime dateDaysAgo = LocalDateTime.now().minusDays(days);
        return postRepository.findRecentPosts(dateDaysAgo).stream()
                .map(postMapper::toDto)
                .toList();
    }

    public List<PostResponse> searchRecentPosts(int days, String content) {
        LocalDateTime dateDaysAgo = LocalDateTime.now().minusDays(days);
        Specification<Post> spec = FeedItemSpecification.hasContent(content);
        return postRepository.findAll(spec).stream()
                .filter(post -> post.getCreatedAt().isAfter(dateDaysAgo))
                .map(postMapper::toDto)
                .toList();
    }

    @Transactional
    public PostResponse createPost(Long shelterId, PostRequest postRequest) {
        Post post = postMapper.toEntity(postRequest);
        post.setShelterId(shelterId);

        post = postRepository.save(post);
        return postMapper.toDto(post);
    }

    @Transactional
    public PostResponse updatePost(Long postId, PostRequest postRequest) {
        Post existingPost = postRepository.findById(postId)
                .orElseThrow(() -> new FeedItemNotFoundException(postId, "Post"));
        existingPost.setTitle(postRequest.title());
        existingPost.setShortDescription(postRequest.shortDescription());

        existingPost.setMainImageId(postRequest.mainImageId());
        existingPost.setLongDescription(postRequest.longDescription());
        existingPost.setFundraisingId(postRequest.fundraisingId());
        existingPost.setImageIds(postRequest.imageIds());

        existingPost = postRepository.save(existingPost);
        return postMapper.toDto(existingPost);
    }

    @Transactional
    public void deletePost(Long postId) {
        if (!postRepository.existsById(postId)) {
            throw new FeedItemNotFoundException(postId, "Post");
        }
        postRepository.deleteById(postId);
    }
}
