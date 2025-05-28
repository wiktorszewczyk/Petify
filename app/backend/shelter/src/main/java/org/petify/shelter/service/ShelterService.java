package org.petify.shelter.service;

import org.petify.shelter.dto.ShelterRequest;
import org.petify.shelter.dto.ShelterResponse;
import org.petify.shelter.exception.RoutingException;
import org.petify.shelter.exception.ShelterAlreadyExistsException;
import org.petify.shelter.exception.ShelterByOwnerNotFoundException;
import org.petify.shelter.exception.ShelterNotFoundException;
import org.petify.shelter.mapper.ShelterMapper;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.ShelterRepository;

import lombok.AllArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.time.Duration;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@AllArgsConstructor
@Service
public class ShelterService {
    private final ShelterRepository shelterRepository;
    private final ShelterMapper shelterMapper;

    public List<ShelterResponse> getShelters() {
        List<Shelter> shelters = shelterRepository.findAll();

        return shelters.stream().map(shelterMapper::toDto).collect(Collectors.toList());
    }

    public ShelterResponse getShelterById(Long shelterId) {
        return shelterRepository.findById(shelterId)
                .map(shelterMapper::toDto)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));
    }

    public ShelterResponse getShelterByOwnerUsername(String username) {
        return shelterRepository.getShelterByOwnerUsername(username)
                .map(shelterMapper::toDto)
                .orElseThrow(() -> new ShelterByOwnerNotFoundException(username));
    }

    @Transactional
    public ShelterResponse createShelter(ShelterRequest input, MultipartFile file, String username) throws IOException {
        if (shelterRepository.getShelterByOwnerUsername(username).isPresent()) {
            throw new ShelterAlreadyExistsException(username);
        }

        Shelter shelter = shelterMapper.toEntity(input);
        shelter.setOwnerUsername(username);

        return setIfImageIncluded(file, shelter);
    }

    @Transactional
    public ShelterResponse updateShelter(ShelterRequest input, MultipartFile file, Long shelterId) throws IOException {
        Shelter existingShelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));

        existingShelter.setName(input.name());
        existingShelter.setDescription(input.description());
        existingShelter.setAddress(input.address());
        existingShelter.setPhoneNumber(input.phoneNumber());
        existingShelter.setLatitude(input.latitude());
        existingShelter.setLongitude(input.longitude());

        return setIfImageIncluded(file, existingShelter);
    }

    private ShelterResponse setIfImageIncluded(MultipartFile file, Shelter existingShelter) throws IOException {
        if (file != null && !file.isEmpty()) {
            existingShelter.setImageName(file.getOriginalFilename());
            existingShelter.setImageType(file.getContentType());
            existingShelter.setImageData(file.getBytes());
        }

        Shelter updatedShelter = shelterRepository.save(existingShelter);

        return shelterMapper.toDto(updatedShelter);
    }

    @Transactional
    public void deleteShelter(Long shelterId) {
        Shelter shelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));

        shelterRepository.delete(shelter);
    }

    public void activateShelter(Long shelterId) {
        Shelter existingShelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));

        existingShelter.setIsActive(true);
        shelterRepository.save(existingShelter);
    }

    public void deactivateShelter(Long shelterId) {
        Shelter existingShelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));

        existingShelter.setIsActive(false);
        shelterRepository.save(existingShelter);
    }

    public String getRouteToShelter(double fromLat, double fromLon, ShelterResponse shelter)
            throws IOException, InterruptedException, RoutingException {

        double toLat = shelter.latitude();
        double toLon = shelter.longitude();

        String osrmUrl = String.format(
                Locale.US,
                "https://router.project-osrm.org/route/v1/driving/%.6f,%.6f;%.6f,%.6f?overview=full&geometries=geojson",
                fromLon, fromLat,
                toLon, toLat
        );

        HttpClient client = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(osrmUrl))
                .timeout(Duration.ofSeconds(10))
                .header("Accept", "application/json")
                .GET()
                .build();

        try {
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() != 200) {
                String errorBody = response.body();
                System.err.println("OSRM Error Response: " + errorBody);
                throw new RoutingException(
                        "OSRM request failed with status: " + response.statusCode()
                                + ", response: " + errorBody
                );
            }

            return response.body();
        } catch (HttpTimeoutException e) {
            throw new RoutingException("OSRM request timed out", e);
        } catch (IOException e) {
            throw new RoutingException("Network error while contacting OSRM", e);
        }
    }
}
