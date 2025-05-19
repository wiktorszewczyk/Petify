package org.petify.funding.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

/**
 * Foreign client for the shelter service to check if a shelter exists.
 */
@FeignClient(
        name = "shelter-service",
        path = "/shelters"
)
public interface ShelterClient {
    @GetMapping("/{shelterId}")
    void checkShelterExists(@PathVariable("shelterId") Long shelterId);

    @GetMapping("/{shelterId}/pets/{petId}")
    void checkPetExists(@PathVariable("shelterId") Long shelterId,
                        @PathVariable("petId") Long petId);
}
