Feature: Create pet

  Scenario: Creating a new pet
    Given I have a pet with name "Rex"
    When I register the pet
    Then the pet should be registered successfully

  Scenario: Creating a pet without a name
    Given I have a pet with name ""
    When I register the pet
    Then the pet should not be registered
