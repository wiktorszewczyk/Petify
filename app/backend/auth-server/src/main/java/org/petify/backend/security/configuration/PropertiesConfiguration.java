package org.petify.backend.security.configuration;

import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;

@Configuration
@PropertySource(value = "file:./secrets.properties", ignoreResourceNotFound = true)
public class PropertiesConfiguration {
    // klasa do ładowania pliku properties
}