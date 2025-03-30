package org.petify.backend.security;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {
   @GetMapping("/")
    public String hello() {
        return "Welcome to Petify!";
    }
}
