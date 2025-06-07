package org.petify.funding.config;

import feign.RequestInterceptor;
import feign.RequestTemplate;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;

@Configuration
public class FeignJwtConfiguration {

    @Bean
    public RequestInterceptor jwtRequestInterceptor() {
        return new RequestInterceptor() {
            @Override
            public void apply(RequestTemplate template) {
                Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

                if (authentication != null && authentication instanceof JwtAuthenticationToken) {
                    JwtAuthenticationToken jwtAuth = (JwtAuthenticationToken) authentication;
                    Jwt jwt = jwtAuth.getToken();

                    template.header("Authorization", "Bearer " + jwt.getTokenValue());
                }
            }
        };
    }
}
