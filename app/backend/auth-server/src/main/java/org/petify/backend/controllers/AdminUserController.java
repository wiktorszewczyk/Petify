package org.petify.backend.controllers;

import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.Role;
import org.petify.backend.models.VolunteerStatus;
import org.petify.backend.repository.RoleRepository;
import org.petify.backend.repository.UserRepository;
import org.petify.backend.services.AuthenticationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/admin/users")
@CrossOrigin("*")
@PreAuthorize("hasRole('ADMIN')")
public class AdminUserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private AuthenticationService authenticationService;

    /**
     * Get all users
     */
    @GetMapping("/")
    public ResponseEntity<List<ApplicationUser>> getAllUsers() {
        List<ApplicationUser> users = userRepository.findAll();
        // Clear sensitive data
        users.forEach(user -> user.setPassword(null));
        return ResponseEntity.ok(users);
    }

    /**
     * Get user by ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<ApplicationUser> getUserById(@PathVariable Integer id) {
        ApplicationUser user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setPassword(null);
        return ResponseEntity.ok(user);
    }

    /**
     * Update user roles
     */
    @PutMapping("/{id}/roles")
    public ResponseEntity<?> updateUserRoles(
            @PathVariable Integer id,
            @RequestBody Set<String> roleNames) {

        try {
            ApplicationUser user = authenticationService.assignRolesToUser(id, roleNames);
            user.setPassword(null);

            Map<String, Object> response = new HashMap<>();
            response.put("message", "User roles updated successfully");
            response.put("userId", user.getUserId());
            response.put("username", user.getUsername());
            response.put("roles", user.getAuthorities());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * Create a new role
     */
    @PostMapping("/roles")
    public ResponseEntity<?> createRole(@RequestBody String roleName) {
        if (roleRepository.findByAuthority(roleName).isPresent()) {
            return ResponseEntity.badRequest().body("Role already exists: " + roleName);
        }

        Role newRole = new Role(roleName);
        roleRepository.save(newRole);

        return ResponseEntity.ok("Role created: " + roleName);
    }

    /**
     * Get all roles
     */
    @GetMapping("/roles")
    public ResponseEntity<List<Role>> getAllRoles() {
        return ResponseEntity.ok(roleRepository.findAll());
    }

    /**
     * Update volunteer status
     */
    @PutMapping("/{id}/volunteer-status")
    public ResponseEntity<?> updateVolunteerStatus(
            @PathVariable Integer id,
            @RequestParam VolunteerStatus status) {

        try {
            ApplicationUser user = authenticationService.updateVolunteerStatus(id, status);
            user.setPassword(null);

            Map<String, Object> response = new HashMap<>();
            response.put("message", "Volunteer status updated");
            response.put("userId", user.getUserId());
            response.put("username", user.getUsername());
            response.put("volunteerStatus", status);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    /**
     * Get all volunteers
     */
    @GetMapping("/volunteers")
    public ResponseEntity<List<ApplicationUser>> getVolunteers() {
        List<ApplicationUser> volunteers = userRepository.findByVolunteerStatusNot(VolunteerStatus.NONE);
        volunteers.forEach(user -> user.setPassword(null));
        return ResponseEntity.ok(volunteers);
    }

    /**
     * Get pending volunteers
     */
    @GetMapping("/pending-volunteers")
    public ResponseEntity<List<ApplicationUser>> getPendingVolunteers() {
        List<ApplicationUser> pendingVolunteers = userRepository.findByVolunteerStatus(VolunteerStatus.PENDING);
        pendingVolunteers.forEach(user -> user.setPassword(null));
        return ResponseEntity.ok(pendingVolunteers);
    }
}