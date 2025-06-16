package org.petify.backend;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(classes = AuthServerApplicationTests.class)
class AuthServerApplicationTests {
    @Test
    void contextLoads() {
        assertTrue(true);
    }
}
