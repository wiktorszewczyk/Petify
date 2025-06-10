package org.petify.image.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.apache.commons.lang.builder.EqualsBuilder;

import java.time.LocalDateTime;

@Entity
@Table(name = "images")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Image {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "image_name")
    private String imageName;
    
    @Column(name = "image_type")
    private String imageType;

    @Column(name = "entity_type", nullable = false)
    private String entityType;
    
    @Lob
    @Column(name = "image_data", nullable = false)
    private byte[] imageData;

    @Column(name = "entity_id", nullable = false)
    private Long entityId;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof Image image)) {
            return false;
        }
        
        return new EqualsBuilder()
                .append(getId(), image.getId())
                .append(getImageName(), image.getImageName())
                .append(getImageType(), image.getImageType())
                .append(getEntityId(), image.getEntityId())
                .isEquals();
    }

    @Override
    public int hashCode() {
        return new org.apache.commons.lang.builder.HashCodeBuilder(17, 37)
                .append(getId())
                .append(getImageName())
                .append(getImageType())
                .append(getEntityId())
                .toHashCode();
    }

    @Override
    public String toString() {
        return new org.apache.commons.lang.builder.ToStringBuilder(this)
                .append("id", id)
                .append("imageName", imageName)
                .append("imageType", imageType)
                .append("entityId", entityId)
                .append("createdAt", createdAt)
                .append("updatedAt", updatedAt)
                .toString();
    }
}
