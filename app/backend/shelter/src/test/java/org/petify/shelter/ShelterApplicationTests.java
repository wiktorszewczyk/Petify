package org.petify.shelter;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(classes = ShelterApplication.class)
class ShelterApplicationTests {
    @Test
    void contextLoads() {
        assertTrue(true);
    }
}
