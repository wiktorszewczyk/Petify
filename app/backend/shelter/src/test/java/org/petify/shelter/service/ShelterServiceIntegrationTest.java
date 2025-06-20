package org.petify.shelter.service;

import org.junit.jupiter.api.Test;
import org.petify.shelter.dto.ShelterRequest;
import org.petify.shelter.dto.ShelterResponse;
import org.petify.shelter.exception.ShelterAlreadyExistsException;
import org.petify.shelter.exception.ShelterByOwnerNotFoundException;
import org.petify.shelter.exception.ShelterNotFoundException;
import org.petify.shelter.integration.BaseIntegrationTest;
import org.petify.shelter.repository.ShelterRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class ShelterServiceIntegrationTest extends BaseIntegrationTest {

    @Autowired
    private ShelterRepository shelterRepository;

    @Autowired
    private ShelterService shelterService;

    @Test
    void createShelter_ShouldSuccessfullyCreateShelter() throws IOException {
        ShelterRequest request = new ShelterRequest(
                "Happy Paws",
                "A shelter for happy pets",
                "123 Pet Street",
                "+48123456789",
                52.2297,
                21.0122
        );

        ShelterResponse response = shelterService.createShelter(request, null, "testuser");

        assertNotNull(response.id());
        assertEquals("Happy Paws", response.name());
        assertEquals("testuser", response.ownerUsername());
    }

    @Test
    void createShelter_ShouldThrowWhenOwnerAlreadyHasShelter() throws IOException {
        ShelterRequest request = new ShelterRequest(
                "First Shelter",
                "First shelter",
                "123 First Street",
                "+48111111111",
                52.2297,
                21.0122
        );

        shelterService.createShelter(request, null, "duplicateuser");

        ShelterRequest secondRequest = new ShelterRequest(
                "Second Shelter",
                "Second shelter",
                "456 Second Street",
                "+48222222222",
                52.2297,
                21.0122
        );

        assertThrows(ShelterAlreadyExistsException.class, () ->
                shelterService.createShelter(secondRequest, null, "duplicateuser"));
    }

    @Test
    void getShelterById_ShouldReturnShelter() throws IOException {
        ShelterRequest request = new ShelterRequest(
                "Find Me Shelter",
                "Should be found by ID",
                "123 Find Street",
                "+48333333333",
                52.2297,
                21.0122
        );

        ShelterResponse created = shelterService.createShelter(request, null, "finduser");
        ShelterResponse found = shelterService.getShelterById(created.id());

        assertEquals(created.id(), found.id());
        assertEquals("Find Me Shelter", found.name());
    }

    @Test
    void getShelterById_ShouldThrowWhenNotFound() {
        assertThrows(ShelterNotFoundException.class, () ->
                shelterService.getShelterById(9999L));
    }

    @Test
    void getShelterByOwnerUsername_ShouldReturnShelter() throws IOException {
        ShelterRequest request = new ShelterRequest(
                "Owner Shelter",
                "Should be found by owner",
                "123 Owner Street",
                "+48444444444",
                52.2297,
                21.0122
        );

        shelterService.createShelter(request, null, "owneruser");
        ShelterResponse found = shelterService.getShelterByOwnerUsername("owneruser");

        assertEquals("Owner Shelter", found.name());
    }

    @Test
    void getShelterByOwnerUsername_ShouldThrowWhenNotFound() {
        assertThrows(ShelterByOwnerNotFoundException.class, () ->
                shelterService.getShelterByOwnerUsername("nonexistentuser"));
    }

    @Test
    void updateShelter_ShouldSuccessfullyUpdate() throws IOException {
        ShelterRequest createRequest = new ShelterRequest(
                "Old Name",
                "Old description",
                "123 Old Street",
                "+48555555555",
                52.2297,
                21.0122
        );

        ShelterResponse created = shelterService.createShelter(createRequest, null, "updateuser");

        ShelterRequest updateRequest = new ShelterRequest(
                "New Name",
                "New description",
                "456 New Street",
                "+48666666666",
                52.2298,
                21.0123
        );

        ShelterResponse updated = shelterService.updateShelter(updateRequest, null, created.id());

        assertEquals(created.id(), updated.id());
        assertEquals("New Name", updated.name());
        assertEquals("New description", updated.description());
        assertEquals("456 New Street", updated.address());
    }

    @Test
    void deleteShelter_ShouldRemoveShelter() throws IOException {
        ShelterRequest request = new ShelterRequest(
                "To Delete",
                "Will be deleted",
                "123 Delete Street",
                "+48777777777",
                52.2297,
                21.0122
        );

        ShelterResponse created = shelterService.createShelter(request, null, "deleteuser");
        shelterService.deleteShelter(created.id());

        assertThrows(ShelterNotFoundException.class, () ->
                shelterService.getShelterById(created.id()));
    }

    @Test
    void getShelters_ShouldReturnAllShelters() throws IOException {
        ShelterRequest request1 = new ShelterRequest(
                "Shelter One",
                "First shelter",
                "123 First Street",
                "+48111111111",
                52.2297,
                21.0122
        );

        ShelterRequest request2 = new ShelterRequest(
                "Shelter Two",
                "Second shelter",
                "456 Second Street",
                "+48222222222",
                52.2298,
                21.0123
        );

        shelterService.createShelter(request1, null, "user1");
        shelterService.createShelter(request2, null, "user2");

        Pageable pageable = PageRequest.of(0, 10);
        Page<ShelterResponse> shelters = shelterService.getShelters(pageable);
        assertTrue(shelters.getSize() >= 2);
    }
}
