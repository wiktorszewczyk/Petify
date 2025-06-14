package org.petify.funding.client;

import org.petify.funding.config.FeignJwtConfiguration;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(
        name = "shelter-service",
        path = "/shelters",
        configuration = FeignJwtConfiguration.class
)
public interface ShelterClient {

    @GetMapping("/{shelterId}/validate")
    void validateShelter(@PathVariable("shelterId") Long shelterId);

    @GetMapping("/{shelterId}/pets/{petId}/validate")
    void validatePetInShelter(@PathVariable("shelterId") Long shelterId,
                              @PathVariable("petId") Long petId);
}
