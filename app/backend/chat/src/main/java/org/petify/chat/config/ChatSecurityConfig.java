package org.petify.chat.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;

@Configuration
@EnableMethodSecurity
@RequiredArgsConstructor
public class ChatSecurityConfig {

    private final JwtDecoder jwtDecoder;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                // 1) wyłączamy CSRF, bo SockJS/STOMP nie wysyłają CSRF-tokena
                .csrf(AbstractHttpConfigurer::disable)
                // 2) globalny CORS
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                // 3) autoryzacja
                .authorizeHttpRequests(auth -> auth
                        // punkt WebSocket-owy (Upgrade) na /ws-chat
                        .requestMatchers(HttpMethod.GET,  "/ws-chat").permitAll()
                        // SockJS będzie korzystać z /ws-chat/info i /ws-chat/{serverId}/xhr_*
                        .requestMatchers(HttpMethod.GET,  "/ws-chat/**").permitAll()
                        .requestMatchers(HttpMethod.POST, "/ws-chat/**").permitAll()
                        .requestMatchers(HttpMethod.OPTIONS, "/ws-chat/**").permitAll()

                        // REST-owe API czatu
                        .requestMatchers(HttpMethod.OPTIONS,"/api/chat/**").permitAll()
                        .requestMatchers("/api/chat/**").authenticated()

                        // zabroń wszystkiego innego
                        .anyRequest().denyAll()
                )
                // 4) resource server do JWT
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt.decoder(jwtDecoder))
                )
                // 5) bez sesji
                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS));

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration cfg = new CorsConfiguration();
        cfg.setAllowedOrigins(Arrays.asList("null"));
        cfg.setAllowedOriginPatterns(Arrays.asList("*"));
        cfg.setAllowCredentials(true);
        cfg.setAllowedMethods(Arrays.asList("GET","POST","PUT","DELETE","OPTIONS"));
        cfg.setAllowedHeaders(Arrays.asList("Authorization","Content-Type"));
        UrlBasedCorsConfigurationSource src = new UrlBasedCorsConfigurationSource();
        src.registerCorsConfiguration("/**", cfg);
        return src;
    }

}
