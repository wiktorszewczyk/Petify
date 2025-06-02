package org.petify.feed.model;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.apache.commons.lang.builder.EqualsBuilder;
import org.apache.commons.lang.builder.HashCodeBuilder;
import org.apache.commons.lang.builder.ToStringBuilder;

import java.util.List;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "posts")
public class Post extends FeedItem {
    @Column(name = "content")
    private String content;

    @Column(name = "main_image_id")
    private Long mainImageId;

    @ElementCollection
    @CollectionTable(name = "post_image_ids", joinColumns = @JoinColumn(name = "post_id"))
    @Column(name = "image_id")
    private List<Long> imageIds;

    public Post(String title, String shortDescription, Long shelterId, Long fundraisingId, String content, Long mainImageId,
                List<Long> imageIds) {
        super(title, shortDescription, shelterId, fundraisingId);
        this.content = content;
        this.mainImageId = mainImageId;
        this.imageIds = imageIds;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof Post post)) {
            return false;
        }
        return new EqualsBuilder()
                .appendSuper(super.equals(o))
                .append(content, post.content)
                .append(mainImageId, post.mainImageId)
                .append(imageIds, post.imageIds)
                .isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37)
                .appendSuper(super.hashCode())
                .append(content)
                .append(mainImageId)
                .append(imageIds)
                .toHashCode();
    }

    @Override
    public String toString() {
        return new ToStringBuilder(this)
                .appendSuper(super.toString())
                .append("content", content)
                .append("mainImageId", mainImageId)
                .append("imageIds", imageIds)
                .toString();
    }
}
