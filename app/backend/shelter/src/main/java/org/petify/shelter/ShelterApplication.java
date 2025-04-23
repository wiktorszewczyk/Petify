package org.petify.shelter;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.oauth2.resourceserver.OAuth2ResourceServerSecurityMarker;

@SpringBootApplication
@EnableDiscoveryClient
@EnableMethodSecurity
public class ShelterApplication {

    public static void main(String[] args) {
        SpringApplication.run(ShelterApplication.class, args);
    }

}
