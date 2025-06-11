package org.petify.feed.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.apache.commons.lang.builder.EqualsBuilder;

import java.time.LocalDateTime;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
@Entity
@Table(name = "events")
public class Event extends FeedItem {
    @Column(name = "start_date", nullable = false)
    private LocalDateTime startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDateTime endDate;

    @Column(name = "address", nullable = false)
    private String address;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    @Column(name = "capacity")
    private Integer capacity;

    public Event(Long mainImageId, String title, String shortDescription, String longDescription,
                 Long shelterId, Long fundraisingId, LocalDateTime startDate, LocalDateTime endDate,
                 String address, Double latitude, Double longitude, Integer capacity) {
        super(mainImageId, title, shortDescription, longDescription, shelterId, fundraisingId);
        this.startDate = startDate;
        this.endDate = endDate;
        this.address = address;
        this.latitude = latitude;
        this.longitude = longitude;
        this.capacity = capacity;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof Event event)) {
            return false;
        }
        return new EqualsBuilder()
                .appendSuper(super.equals(o))
                .append(startDate, event.startDate)
                .append(endDate, event.endDate)
                .append(address, event.address)
                .append(latitude, event.latitude)
                .append(longitude, event.longitude)
                .append(capacity, event.capacity)
                .isEquals();
    }

    @Override
    public int hashCode() {
        return new org.apache.commons.lang.builder.HashCodeBuilder(17, 37)
                .appendSuper(super.hashCode())
                .append(startDate)
                .append(endDate)
                .append(address)
                .append(latitude)
                .append(longitude)
                .append(capacity)
                .toHashCode();
    }

    @Override
    public String toString() {
        return new org.apache.commons.lang.builder.ToStringBuilder(this)
                .appendSuper(super.toString())
                .append("startDate", startDate)
                .append("endDate", endDate)
                .append("address", address)
                .append("latitude", latitude)
                .append("longitude", longitude)
                .append("capacity", capacity)
                .toString();
    }
}
