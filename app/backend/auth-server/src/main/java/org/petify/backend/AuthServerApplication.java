package org.petify.backend;

import org.petify.backend.security.models.ApplicationUser;
import org.petify.backend.security.models.Role;
import org.petify.backend.security.repository.RoleRepository;
import org.petify.backend.security.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.HashSet;
import java.util.Set;

@SpringBootApplication
public class AuthServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(AuthServerApplication.class, args);
    }

    @Bean
    CommandLineRunner run(RoleRepository roleRepository, UserRepository userRepository, PasswordEncoder passwordEncode) {
        return args -> {
            if (roleRepository.findByAuthority("ADMIN").isPresent()) {
                return;
            }

            Role adminRole = roleRepository.save(new Role("ADMIN"));
            roleRepository.save(new Role("USER"));

            Set<Role> roles = new HashSet<>();
            roles.add(adminRole);

            ApplicationUser admin = new ApplicationUser();
            admin.setUsername("admin");
            admin.setPassword(passwordEncode.encode("admin"));
            admin.setAuthorities(roles);

            userRepository.save(admin);
        };
    }
}
