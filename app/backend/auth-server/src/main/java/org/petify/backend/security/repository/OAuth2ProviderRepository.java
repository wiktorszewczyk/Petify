package org.petify.backend.security.repository;

import org.petify.backend.security.models.OAuth2Provider;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OAuth2ProviderRepository extends JpaRepository<OAuth2Provider, Long> {
    Optional<OAuth2Provider> findByProviderIdAndProviderUserId(String providerId, String providerUserId);
}
