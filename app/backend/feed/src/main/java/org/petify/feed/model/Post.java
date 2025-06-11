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
    @ElementCollection
    @CollectionTable(name = "post_image_ids", joinColumns = @JoinColumn(name = "post_id"))
    @Column(name = "image_id")
    private List<Long> imageIds;

    public Post(Long shelterId, String title, String shortDescription, Long mainImageId,
                String longDescription, Long fundraisingId, List<Long> imageIds) {
        super(shelterId, title, shortDescription, mainImageId, longDescription, fundraisingId);
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
                .append(imageIds, post.imageIds)
                .isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37)
                .appendSuper(super.hashCode())
                .append(imageIds)
                .toHashCode();
    }

    @Override
    public String toString() {
        return new ToStringBuilder(this)
                .appendSuper(super.toString())
                .append("imageIds", imageIds)
                .toString();
    }
}
