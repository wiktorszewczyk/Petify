package org.petify.backend.models;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

/**
 * Class representing the connection between a user account in our application
 * and their account with an external OAuth2 provider (e.g., Google)
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
    private String providerId;  // e.g., "google", "github"

    @Column(nullable = false)
    private String providerUserId;  // User ID at the provider

    /**
     * Relation to the user in our application.
     * Note: user must already be saved in the database (have an ID)
     * before saving an OAuth2Provider object.
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false,
            foreignKey = @ForeignKey(name = "fk_oauth2provider_user",
                    foreignKeyDefinition = "FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE"))
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