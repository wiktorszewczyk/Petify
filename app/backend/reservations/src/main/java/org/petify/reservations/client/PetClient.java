package org.petify.reservations.client;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.List;

@FeignClient(
        name = "shelter-service",
        path = "/pets"
)
public interface PetClient {


    @GetMapping("/ids")
    List<Long> getAllPetIds();
}
