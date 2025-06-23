package org.petify.shelter.cucumber;

import io.cucumber.java.en.*;
import static org.junit.jupiter.api.Assertions.*;

public class PetSteps {
    private String petName;
    private boolean registered;

    @Given("I have a pet with name {string}")
    public void i_have_a_pet_with_name(String name) {
        this.petName = name;
    }

    @When("I register the pet")
    public void i_register_the_pet() {
        if (petName != null && !petName.isEmpty()) {
            registered = true;
        }
    }

    @Then("the pet should be registered successfully")
    public void the_pet_should_be_registered_successfully() {
        assertTrue(registered);
    }

    @Then("the pet should not be registered")
    public void the_pet_should_not_be_registered() {
        assertFalse(registered);
    }
}
