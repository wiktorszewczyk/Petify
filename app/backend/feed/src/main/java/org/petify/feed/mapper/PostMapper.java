package org.petify.feed.mapper;

import org.petify.feed.dto.PostRequest;
import org.petify.feed.dto.PostResponse;
import org.petify.feed.model.Post;

import org.mapstruct.Mapper;
import org.mapstruct.MappingConstants;
import org.mapstruct.ReportingPolicy;

@Mapper(unmappedTargetPolicy = ReportingPolicy.IGNORE, componentModel = MappingConstants.ComponentModel.SPRING)
public interface PostMapper {
    Post toEntity(PostRequest postRequest);

    PostResponse toDto(Post post);
}
