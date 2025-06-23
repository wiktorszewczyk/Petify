Feature: Create Shelter

  Scenario: User creates a new shelter
    Given no shelter exists for owner "john_doe"
    And I prepare a shelter request with name "New Hope"
    And I attach an image file
    When I submit the request as owner "john_doe"
    Then the shelter should be created
    And the response should contain name "New Hope"
