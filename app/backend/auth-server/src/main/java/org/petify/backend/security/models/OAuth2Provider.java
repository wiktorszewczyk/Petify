package org.petify.backend.security.models;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

/**
 * Klasa reprezentująca połączenie między kontem użytkownika w naszej aplikacji
 * a jego kontem u zewnętrznego dostawcy OAuth2 (np. Google)
 */
@Getter
@Setter
@Entity
@Table(name = "oauth2_providers")
public class OAuth2Provider {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String providerId;  // np. "google", "github"

    @Column(nullable = false)
    private String providerUserId;  // ID użytkownika u dostawcy OAuth2

    /**
     * Relacja do użytkownika w naszej aplikacji.
     * Uwaga: user musi być już zapisany w bazie danych (posiadać ID)
     * przed zapisaniem obiektu OAuth2Provider.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private ApplicationUser user;

    @Column
    private String email;

    @Column
    private String name;

    public OAuth2Provider() {
    }

    public OAuth2Provider(String providerId, String providerUserId, ApplicationUser user,
                          String email, String name) {
        this.providerId = providerId;
        this.providerUserId = providerUserId;
        this.user = user;
        this.email = email;
        this.name = name;
    }
}
