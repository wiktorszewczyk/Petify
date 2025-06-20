package org.petify.backend.models;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

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
    private String providerUserId;

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
