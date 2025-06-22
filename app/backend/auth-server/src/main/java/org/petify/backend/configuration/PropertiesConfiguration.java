package org.petify.backend.configuration;

import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.PropertySource;

@Configuration
@PropertySource(value = "file:./app/backend/secrets.properties", ignoreResourceNotFound = true)
public class PropertiesConfiguration {
    // klasa do ładowania pliku properties
}
