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
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

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

    @GetMapping("/")
    public ResponseEntity<List<ApplicationUser>> getAllUsers() {
        List<ApplicationUser> users = userRepository.findAll();
        users.forEach(user -> user.setPassword(null));
        return ResponseEntity.ok(users);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApplicationUser> getUserById(@PathVariable Integer id) {
        ApplicationUser user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setPassword(null);
        return ResponseEntity.ok(user);
    }

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

    @GetMapping("/roles")
    public ResponseEntity<List<Role>> getAllRoles() {
        return ResponseEntity.ok(roleRepository.findAll());
    }

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

    @GetMapping("/volunteers")
    public ResponseEntity<List<ApplicationUser>> getVolunteers() {
        List<ApplicationUser> volunteers = userRepository.findByVolunteerStatusNot(VolunteerStatus.NONE);
        volunteers.forEach(user -> user.setPassword(null));
        return ResponseEntity.ok(volunteers);
    }

    @GetMapping("/pending-volunteers")
    public ResponseEntity<List<ApplicationUser>> getPendingVolunteers() {
        List<ApplicationUser> pendingVolunteers = userRepository.findByVolunteerStatus(VolunteerStatus.PENDING);
        pendingVolunteers.forEach(user -> user.setPassword(null));
        return ResponseEntity.ok(pendingVolunteers);
    }

    @PutMapping("/{id}/deactivate")
    public ResponseEntity<?> deactivateUser(
            @PathVariable Integer id,
            @RequestParam(required = false) String reason) {

        try {
            ApplicationUser user = authenticationService.deactivateUserAccount(id, reason);
            user.setPassword(null);

            Map<String, Object> response = new HashMap<>();
            response.put("message", "User account has been deactivated");
            response.put("userId", user.getUserId());
            response.put("username", user.getUsername());
            response.put("active", user.isActive());
            if (reason != null) {
                response.put("deactivationReason", user.getDeactivationReason());
            }

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PutMapping("/{id}/activate")
    public ResponseEntity<?> activateUser(@PathVariable Integer id) {
        try {
            ApplicationUser user = authenticationService.reactivateUserAccount(id);
            user.setPassword(null);

            Map<String, Object> response = new HashMap<>();
            response.put("message", "User account has been reactivated");
            response.put("userId", user.getUserId());
            response.put("username", user.getUsername());
            response.put("active", user.isActive());

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/inactive")
    public ResponseEntity<List<ApplicationUser>> getInactiveUsers() {
        List<ApplicationUser> inactiveUsers = userRepository.findByActiveIsFalse();
        inactiveUsers.forEach(user -> user.setPassword(null));
        return ResponseEntity.ok(inactiveUsers);
    }
}
