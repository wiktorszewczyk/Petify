package org.petify.funding;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@SpringBootApplication
@EnableDiscoveryClient
@EnableFeignClients(basePackages = "org.petify.funding.client")
public class FundingApplication {
    public static void main(String[] args) {
        SpringApplication.run(FundingApplication.class, args);
    }
}
