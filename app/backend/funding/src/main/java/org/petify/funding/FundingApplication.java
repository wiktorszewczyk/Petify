package org.petify.funding;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
public class FundingApplication {
    public static void main(String[] args) {
        SpringApplication.run(FundingApplication.class, args);
    }
}
