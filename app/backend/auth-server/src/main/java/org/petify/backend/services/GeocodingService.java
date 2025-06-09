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

    private static final String USER_AGENT = "Petify-App/1.0";
    private static final String POLAND_SUFFIX = ", Poland";
    private static final String ACCEPT_JSON = "application/json";
    private static final Duration CONNECT_TIMEOUT = Duration.ofSeconds(5);
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(10);
    private static final String COUNTRY_POLAND = "Poland";

    private final ObjectMapper objectMapper = new ObjectMapper();

    private HttpResponse<String> executeHttpRequest(String url) throws IOException, InterruptedException {
        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(CONNECT_TIMEOUT)
                .build();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .timeout(REQUEST_TIMEOUT)
                .header("Accept", ACCEPT_JSON)
                .header("User-Agent", USER_AGENT)
                .GET()
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            throw new RuntimeException("Request failed with status: " + response.statusCode());
        }

        return response;
    }

    private String extractCityName(JsonNode address) {
        if (address == null) {
            return "";
        }

        String[] cityFields = {"city", "town", "village", "municipality"};
        for (String field : cityFields) {
            if (address.has(field)) {
                return address.get(field).asText();
            }
        }
        return "";
    }

    private AddressInfo extractAddressInfo(JsonNode address) {
        String country = address != null && address.has("country")
                ? address.get("country").asText() : COUNTRY_POLAND;
        String state = address != null && address.has("state")
                ? address.get("state").asText() : "";

        return new AddressInfo(country, state);
    }

    @Cacheable(value = "geocoding", key = "#cityName.toLowerCase().strip()")
    public GeolocationResponse getCoordinatesForCity(String cityName) throws Exception {
        if (cityName == null || cityName.trim().isEmpty()) {
            throw new IllegalArgumentException("City name cannot be empty");
        }

        String encodedCity = URLEncoder.encode(cityName.trim() + POLAND_SUFFIX, StandardCharsets.UTF_8);
        String nominatimUrl = "https://nominatim.openstreetmap.org/search?q=" + encodedCity
                + "&format=json&limit=1&addressdetails=1";

        try {
            HttpResponse<String> response = executeHttpRequest(nominatimUrl);
            JsonNode results = objectMapper.readTree(response.body());

            if (results.isEmpty()) {
                throw new RuntimeException("No coordinates found for city: " + cityName);
            }

            JsonNode firstResult = results.get(0);
            double lat = firstResult.get("lat").asDouble();
            double lon = firstResult.get("lon").asDouble();

            JsonNode address = firstResult.get("address");
            AddressInfo addressInfo = extractAddressInfo(address);
            String displayName = firstResult.has("display_name")
                    ? firstResult.get("display_name").asText() : cityName;

            return new GeolocationResponse(cityName.trim(), lat, lon,
                    addressInfo.country(), addressInfo.state(), displayName);

        } catch (HttpTimeoutException e) {
            throw new RuntimeException("Geocoding request timed out for city: " + cityName, e);
        } catch (IOException | InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Error while getting coordinates for city: " + cityName, e);
        }
    }

    @Cacheable(value = "city-suggestions", key = "#query.toLowerCase().strip()")
    public List<GeolocationResponse> searchCities(String query) throws Exception {
        if (query == null || query.trim().isEmpty()) {
            return new ArrayList<>();
        }

        String encodedQuery = URLEncoder.encode(query.trim() + POLAND_SUFFIX, StandardCharsets.UTF_8);
        String nominatimUrl = "https://nominatim.openstreetmap.org/search?q=" + encodedQuery
                + "&format=json&limit=5&addressdetails=1&class=place&type=city,town,village";

        try {
            HttpResponse<String> response = executeHttpRequest(nominatimUrl);
            JsonNode results = objectMapper.readTree(response.body());
            List<GeolocationResponse> cities = new ArrayList<>();

            for (JsonNode result : results) {
                double lat = result.get("lat").asDouble();
                double lon = result.get("lon").asDouble();

                JsonNode address = result.get("address");
                String cityName = extractCityName(address);

                if (!cityName.isEmpty()) {
                    AddressInfo addressInfo = extractAddressInfo(address);
                    String displayName = result.has("display_name")
                            ? result.get("display_name").asText() : cityName;

                    cities.add(new GeolocationResponse(cityName, lat, lon,
                            addressInfo.country(), addressInfo.state(), displayName));
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

    public boolean isCityValid(String cityName) {
        try {
            GeolocationResponse result = getCoordinatesForCity(cityName);
            return result != null && COUNTRY_POLAND.equalsIgnoreCase(result.country());
        } catch (Exception e) {
            return false;
        }
    }

    private record AddressInfo(String country, String state) {}
}
