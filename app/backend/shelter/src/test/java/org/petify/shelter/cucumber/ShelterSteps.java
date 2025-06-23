package org.petify.shelter.cucumber;

import io.cucumber.java.en.*;
import lombok.RequiredArgsConstructor;
import org.junit.jupiter.api.Assertions;
import org.petify.shelter.dto.ShelterRequest;
import org.petify.shelter.dto.ShelterResponse;
import org.petify.shelter.exception.ShelterNotFoundException;
import org.petify.shelter.model.Shelter;
import org.petify.shelter.repository.ShelterRepository;
import org.petify.shelter.service.ShelterService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.mock.web.MockMultipartFile;

import java.nio.charset.StandardCharsets;

@SpringBootTest
@RequiredArgsConstructor(onConstructor_ = @Autowired)
public class ShelterSteps {

    private final ShelterService shelterService;
    private final ShelterRepository shelterRepository;

    private ShelterRequest shelterRequest;
    private ShelterResponse shelterResponse;
    private MockMultipartFile mockFile;
    private Long shelterId;
    private String ownerUsername;
    private String routeResult;

    @Given("a shelter with ID {long} exists in the system")
    public void aShelterWithIdExists(long id) {
        Shelter shelter = new Shelter();
        shelter.setId(id);
        shelter.setName("Happy Paws Shelter");
        shelter.setOwnerUsername("owner_" + id);
        shelter.setIsActive(false);
        shelterRepository.save(shelter);
        this.shelterId = id;
    }

    @When("I request the shelter with ID {long}")
    public void iRequestTheShelterWithId(long id) {
        shelterResponse = shelterService.getShelterById(id);
    }

    @Then("the response should contain shelter name {string}")
    public void theResponseShouldContainShelterName(String name) {
        Assertions.assertEquals(name, shelterResponse.name());
    }

    @Given("no shelter exists for owner {string}")
    public void noShelterExistsForOwner(String username) {
        shelterRepository.findById(1L).ifPresent(shelter -> shelterRepository.delete(shelter));
        this.ownerUsername = username;
    }

    @And("I prepare a shelter request with name {string}")
    public void iPrepareAShelterRequestWithName(String name) {
        this.shelterRequest = new ShelterRequest(
                name,
                "Test Description",
                "Test Address",
                "123-456-789",
                50.0,
                19.0
        );
    }

    @And("I attach an image file")
    public void iAttachAnImageFile() {
        mockFile = new MockMultipartFile(
                "file",
                "test.jpg",
                "image/jpeg",
                "fake image content".getBytes(StandardCharsets.UTF_8)
        );
    }

    @When("I submit the request as owner {string}")
    public void iSubmitTheRequestAsOwner(String username) throws Exception {
        shelterResponse = shelterService.createShelter(shelterRequest, mockFile, username);
        shelterId = shelterResponse.id();
    }

    @Then("the shelter should be created")
    public void theShelterShouldBeCreated() {
        Assertions.assertNotNull(shelterResponse);
        Assertions.assertNotNull(shelterResponse.id());
    }

    @And("the response should contain name {string}")
    public void theResponseShouldContainName(String name) {
        Assertions.assertEquals(name, shelterResponse.name());
    }

    @Then("the shelter should be marked as active")
    public void theShelterShouldBeMarkedAsActive() {
        Shelter shelter = shelterRepository.findById(shelterId)
                .orElseThrow(() -> new ShelterNotFoundException(shelterId));
        Assertions.assertTrue(shelter.getIsActive());
    }
}
