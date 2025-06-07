package org.petify.funding.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.Map;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WebhookEventDto {
    private String eventId;
    private String eventType;
    private String provider;
    private String externalPaymentId;
    private Map<String, Object> eventData;
    private Instant receivedAt;
    private boolean processed;
}
