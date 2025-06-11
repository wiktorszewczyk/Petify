package org.petify.shelter;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;

@SpringBootApplication
@EnableDiscoveryClient
@EnableMethodSecurity
@EnableFeignClients(basePackages = "org.petify.shelter.client")
public class ShelterApplication {

    public static void main(String[] args) {
        SpringApplication.run(ShelterApplication.class, args);
    }
}
