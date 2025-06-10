package org.petify.feed.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Inheritance;
import jakarta.persistence.InheritanceType;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.apache.commons.lang.builder.EqualsBuilder;
import org.apache.commons.lang.builder.HashCodeBuilder;
import org.apache.commons.lang.builder.ToStringBuilder;

import java.time.LocalDateTime;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Entity
@Inheritance(strategy = InheritanceType.JOINED)
@Table(name = "feed_items")
public abstract class FeedItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "main_image_id")
    private Long mainImageId;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "short_description", nullable = false)
    private String shortDescription;

    @Column(name = "shelter_id", nullable = false)
    private Long shelterId;

    @Column(name = "fundraising_id")
    private Long fundraisingId;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    public FeedItem(Long mainImageId, String title, String shortDescription, Long shelterId, Long fundraisingId) {
        this.mainImageId = mainImageId;
        this.title = title;
        this.shortDescription = shortDescription;
        this.shelterId = shelterId;
        this.fundraisingId = fundraisingId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof FeedItem feedItem)) {
            return false;
        }

        return new EqualsBuilder()
                .append(getMainImageId(), feedItem.getMainImageId())
                .append(getTitle(), feedItem.getTitle())
                .append(getShortDescription(), feedItem.getShortDescription())
                .append(getShelterId(), feedItem.getShelterId())
                .append(getFundraisingId(), feedItem.getFundraisingId())
                .isEquals();
    }

    @Override
    public int hashCode() {
        return new HashCodeBuilder(17, 37)
                .append(getMainImageId())
                .append(getTitle())
                .append(getShortDescription())
                .append(getShelterId())
                .append(getFundraisingId())
                .toHashCode();
    }

    @Override
    public String toString() {
        return new ToStringBuilder(this)
                .append("id", id)
                .append("createdAt", createdAt)
                .append("mainImageId", mainImageId)
                .append("title", title)
                .append("shortDescription", shortDescription)
                .append("shelterId", shelterId)
                .append("fundraisingId", fundraisingId)
                .toString();
    }
}
