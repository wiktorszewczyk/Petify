package org.petify.backend.services;

import org.petify.backend.dto.GeolocationResponse;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class GeocodingService {

    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Pobiera współrzędne geograficzne dla danego miasta używając Nominatim API (OpenStreetMap)
     * Wyniki są cache'owane żeby nie wykonywać zbędnych zapytań dla tego samego miasta
     */
    @Cacheable(value = "geocoding", key = "#cityName.toLowerCase().strip()")
    public GeolocationResponse getCoordinatesForCity(String cityName) throws Exception {
        if (cityName == null || cityName.trim().isEmpty()) {
            throw new IllegalArgumentException("City name cannot be empty");
        }

        String encodedCity = URLEncoder.encode(cityName.trim() + ", Poland", StandardCharsets.UTF_8);
        String nominatimUrl = "https://nominatim.openstreetmap.org/search?q=" + encodedCity
                + "&format=json&limit=1&addressdetails=1";

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(nominatimUrl))
                .timeout(Duration.ofSeconds(10))
                .header("Accept", "application/json")
                .header("User-Agent", "Petify-App/1.0")
                .GET()
                .build();

        try {
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                throw new RuntimeException("Geocoding request failed with status: " + response.statusCode());
            }

            JsonNode results = objectMapper.readTree(response.body());

            if (results.isEmpty()) {
                throw new RuntimeException("No coordinates found for city: " + cityName);
            }

            JsonNode firstResult = results.get(0);
            double lat = firstResult.get("lat").asDouble();
            double lon = firstResult.get("lon").asDouble();

            JsonNode address = firstResult.get("address");
            String country = address != null && address.has("country")
                    ? address.get("country").asText() : "Poland";
            String state = address != null && address.has("state")
                    ? address.get("state").asText() : "";
            String displayName = firstResult.has("display_name")
                    ? firstResult.get("display_name").asText() : cityName;

            return new GeolocationResponse(cityName.trim(), lat, lon, country, state, displayName);

        } catch (HttpTimeoutException e) {
            throw new RuntimeException("Geocoding request timed out for city: " + cityName, e);
        } catch (IOException | InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Error while getting coordinates for city: " + cityName, e);
        }
    }

    /**
     * Wyszukuje sugestie miast na podstawie wprowadzonego tekstu
     */
    @Cacheable(value = "city-suggestions", key = "#query.toLowerCase().strip()")
    public List<GeolocationResponse> searchCities(String query) throws Exception {
        if (query == null || query.trim().isEmpty()) {
            return new ArrayList<>();
        }

        String encodedQuery = URLEncoder.encode(query.trim() + ", Poland", StandardCharsets.UTF_8);
        String nominatimUrl = "https://nominatim.openstreetmap.org/search?q=" + encodedQuery
                + "&format=json&limit=5&addressdetails=1&class=place&type=city,town,village";

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(nominatimUrl))
                .timeout(Duration.ofSeconds(10))
                .header("Accept", "application/json")
                .header("User-Agent", "Petify-App/1.0")
                .GET()
                .build();

        try {
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                throw new RuntimeException("City search request failed with status: " + response.statusCode());
            }

            JsonNode results = objectMapper.readTree(response.body());
            List<GeolocationResponse> cities = new ArrayList<>();

            for (JsonNode result : results) {
                double lat = result.get("lat").asDouble();
                double lon = result.get("lon").asDouble();

                JsonNode address = result.get("address");
                String cityName = "";

                if (address != null) {
                    if (address.has("city")) {
                        cityName = address.get("city").asText();
                    } else if (address.has("town")) {
                        cityName = address.get("town").asText();
                    } else if (address.has("village")) {
                        cityName = address.get("village").asText();
                    } else if (address.has("municipality")) {
                        cityName = address.get("municipality").asText();
                    }
                }

                String country = address != null && address.has("country")
                        ? address.get("country").asText() : "Poland";
                String state = address != null && address.has("state")
                        ? address.get("state").asText() : "";
                String displayName = result.has("display_name")
                        ? result.get("display_name").asText() : cityName;

                if (!cityName.isEmpty()) {
                    cities.add(new GeolocationResponse(cityName, lat, lon, country, state, displayName));
                }
            }

            return cities;

        } catch (HttpTimeoutException e) {
            throw new RuntimeException("City search request timed out for query: " + query, e);
        } catch (IOException | InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Error while searching cities: " + query, e);
        }
    }

    /**
     * Sprawdza czy podane miasto istnieje w Polsce
     */
    public boolean isCityValid(String cityName) {
        try {
            GeolocationResponse result = getCoordinatesForCity(cityName);
            return result != null && "Poland".equalsIgnoreCase(result.country());
        } catch (Exception e) {
            return false;
        }
    }
}
