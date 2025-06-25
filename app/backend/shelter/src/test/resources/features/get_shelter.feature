Feature: Get Shelter by ID

  Scenario: Shelter with given ID exists
    Given a shelter with ID 1 exists in the system
    When I request the shelter with ID 1
    Then the response should contain shelter name "Happy Paws Shelter"