package org.petify.reservations.client;

import org.petify.reservations.config.FeignConfig;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import java.util.List;

@FeignClient(name = "shelter-service", configuration = FeignConfig.class)
public interface PetClient {

    @GetMapping("/pets/ids")
    List<Long> getAllPetIds();

    @GetMapping("/shelters/{petId}/owner")
    String getOwnerByPetId(@PathVariable("petId") Long petId);

    @GetMapping("/pets/shelter/{shelterId}/ids")
    List<Long> getPetIdsByShelterId(@PathVariable Long shelterId);

    @GetMapping("/shelters/my-shelter/id")
    Long getMyShelterIdAndVerifyOwnership();

    @GetMapping("/pets/{petId}/archived")
    Boolean isPetArchived(@PathVariable Long petId);
}
