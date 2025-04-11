package org.petify.shelter.feign;

import org.springframework.cloud.openfeign.FeignClient;

@FeignClient("AUTH-SERVICE")
public interface AuthInterface {

}
