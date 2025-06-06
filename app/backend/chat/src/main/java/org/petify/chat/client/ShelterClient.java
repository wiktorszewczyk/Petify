package org.petify.chat.client;

import org.petify.chat.config.FeignConfig;

import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "shelter-service", configuration = FeignConfig.class)
public interface ShelterClient {

    @GetMapping("/shelters/{petId}/owner")
    String getShelterOwner(@PathVariable("petId") Long petId);
}


