package org.petify.backend;

import java.util.HashSet;
import java.util.Set;

import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.Role;
import org.petify.backend.repository.RoleRepository;
import org.petify.backend.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.password.PasswordEncoder;

@SpringBootApplication
public class AuthServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(AuthServerApplication.class, args);
    }

    @Bean
    CommandLineRunner run(RoleRepository roleRepository, UserRepository userRepository, PasswordEncoder passwordEncode) {
        return args -> {
            if(roleRepository.findByAuthority("ADMIN").isPresent()) return;

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
