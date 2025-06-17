package org.petify.gateway.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.reactive.CorsWebFilter;
import org.springframework.web.cors.reactive.UrlBasedCorsConfigurationSource;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.Arrays;

/**
 * Klasa konfiguracyjna dla Gateway - zawiera zarówno konfigurację security jak i filtry.
 */
@Configuration
@EnableWebFluxSecurity
public class GatewayConfiguration {

    private static final Logger log = LoggerFactory.getLogger(GatewayConfiguration.class);

    /**
     * Konfiguracja bezpieczeństwa
     */
    @Bean
    public SecurityWebFilterChain springSecurityFilterChain(ServerHttpSecurity http) {
        return http
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .cors(Customizer.withDefaults())
                .authorizeExchange(exchanges -> exchanges
                        .anyExchange().permitAll()
                )
                .build();
    }

    /**
     * Konfiguracja CORS
     */
    @Bean
    public CorsWebFilter corsWebFilter() {
        CorsConfiguration corsConfig = new CorsConfiguration();
        corsConfig.setAllowedOrigins(Arrays.asList("*"));
        corsConfig.setMaxAge(3600L);
        corsConfig.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        corsConfig.setAllowedHeaders(Arrays.asList("Authorization", "Content-Type", "X-Requested-With"));
        corsConfig.setExposedHeaders(Arrays.asList("Authorization"));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", corsConfig);
        return new CorsWebFilter(source);
    }

    /**
     * Filtr do logowania żądań i odpowiedzi
     */
    @Bean
    public GlobalFilter loggingFilter() {
        return new GlobalFilter() {
            @Override
            public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
                ServerHttpRequest request = exchange.getRequest();

                // Logowanie szczegółów żądania
                log.info("Gateway Request: {} {}", request.getMethod(), request.getPath());

                // Logowanie nagłówków (z ukryciem wrażliwych danych)
                request.getHeaders().forEach((name, values) -> {
                    values.forEach(value -> {
                        if (name.equalsIgnoreCase("authorization")) {
                            if (value.startsWith("Bearer ") && value.length() > 15) {
                                log.info("Header: {}: Bearer {}...", name, value.substring(7, 15));
                            } else {
                                log.info("Header: {}: [masked]", name);
                            }
                        } else {
                            log.info("Header: {}: {}", name, value);
                        }
                    });
                });

                // Logowanie odpowiedzi
                return chain.filter(exchange)
                        .then(Mono.fromRunnable(() -> {
                            ServerHttpResponse response = exchange.getResponse();
                            log.info("Gateway Response: {} for {} {}",
                                    response.getStatusCode(),
                                    request.getMethod(),
                                    request.getPath());
                        }));
            }
        };
    }

    /**
     * Filtr do przekazywania nagłówka Authorization
     */
    @Bean
    public GlobalFilter authHeaderFilter() {
        return new GlobalFilter() {
            @Override
            public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
                ServerHttpRequest request = exchange.getRequest();

                if (request.getHeaders().containsKey("Authorization")) {
                    String authHeader = request.getHeaders().getFirst("Authorization");

                    // Utwórz nowe żądanie z jawnie przekazanym nagłówkiem Authorization
                    ServerHttpRequest modifiedRequest = request.mutate()
                            .header("Authorization", authHeader)
                            .build();

                    return chain.filter(exchange.mutate().request(modifiedRequest).build());
                }

                return chain.filter(exchange);
            }
        };
    }
}
