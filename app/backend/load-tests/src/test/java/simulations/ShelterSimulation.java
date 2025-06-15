package simulations;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.*;

import io.gatling.javaapi.core.*;
import io.gatling.javaapi.http.*;

public class ShelterSimulation extends Simulation {

    private static final String BASE_URL = "http://localhost:8010";

    // dynamic token - require change every time for testing
    private static final String AUTH_TOKEN = "Bearer eyJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjkwMDAiLCJzdWIiOiJhZG1pbiIsImF1dGhfbWV0aG9kIjoiZm9ybSIsImV4cCI6MTc0OTk5MDEzMywiaWF0IjoxNzQ5OTAzNzMzLCJyb2xlcyI6WyJVU0VSIiwiQURNSU4iXX0.zg0uDKUECpoGSaBrvWg8aRly7kk36NQ4n5jqjwEdHey67VUfTFuLUG6kygIGKUCesM88GWd2QYKc1_ub-aNoo2yuriyIQs4phxS891Wpbp_4RuBRqc-DSrHLdypa7TTcKmQj1bXL5L0ShaG086zv1g5Tf0q4ixnkJKeARW2ldeLoX6LakOtVehpCPZeZVN8WtKxRFCdOLJJjsYYcGxhtNzRC6dSiaugRwp8Vhvw1k-up5DXjj-PQqgJQi1iOs2Vlaf-W189zcrasT_M6bppAFr03pYmoutrbT3NVUn2JBWb9iFqd65Hx9MsfvhqQ23wqosYvykLeATdAAXySW6RWMg"; // Replace with real token

    HttpProtocolBuilder httpProtocol = http
            .baseUrl(BASE_URL)
            .acceptHeader("application/json")
            .contentTypeHeader("application/json");

    ScenarioBuilder getShelters = scenario("Get All Shelters")
            .exec(http("GET /shelters")
                    .get("/shelters")
                    .check(status().is(200)));

    ScenarioBuilder getShelterById = scenario("Get Shelter by ID")
            .exec(http("GET /shelters/1")
                    .get("/shelters/1")
                    .header("Authorization", AUTH_TOKEN)
                    .check(status().in(200, 403, 404)));

    ScenarioBuilder routeToShelter = scenario("Get Shelter Route")
            .exec(http("GET /shelters/1/route")
                    .get("/shelters/1/route?latitude=51.1&longitude=17.02")
                    .check(status().in(200, 400, 404)));

    ScenarioBuilder validateShelter = scenario("Validate Shelter for Donation")
            .exec(http("GET /shelters/1/validate")
                    .get("/shelters/1/validate")
                    .header("Authorization", AUTH_TOKEN)
                    .check(status().in(200, 404)));

    ScenarioBuilder validatePet = scenario("Validate Pet in Shelter")
            .exec(http("GET /shelters/1/pets/1/validate")
                    .get("/shelters/1/pets/1/validate")
                    .header("Authorization", AUTH_TOKEN)
                    .check(status().in(200, 404)));

    {
        setUp(
                getShelters.injectOpen(atOnceUsers(10)),
                getShelterById.injectOpen(rampUsers(10).during(10)),
                routeToShelter.injectOpen(atOnceUsers(5)),
                validateShelter.injectOpen(atOnceUsers(5)),
                validatePet.injectOpen(atOnceUsers(5))
        ).protocols(httpProtocol);
    }
}
