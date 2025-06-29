package org.petify.backend.controllers;

import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.VolunteerApplication;
import org.petify.backend.models.VolunteerStatus;
import org.petify.backend.repository.UserRepository;
import org.petify.backend.services.VolunteerService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/volunteer")
public class VolunteerController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private VolunteerService volunteerService;

    @PostMapping("/apply")
    public ResponseEntity<?> applyForVolunteer(@RequestBody VolunteerApplication application) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();

        try {
            VolunteerApplication savedApplication = volunteerService.applyForVolunteer(username, application);
            return new ResponseEntity<>(savedApplication, HttpStatus.CREATED);
        } catch (IllegalStateException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error submitting volunteer application: " + e.getMessage());
        }
    }

    @GetMapping("/status")
    public ResponseEntity<?> getVolunteerStatus() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();

        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        Map<String, Object> response = new HashMap<>();
        response.put("volunteerStatus", user.getVolunteerStatus());

        if (user.getVolunteerStatus() != VolunteerStatus.NONE) {
            List<VolunteerApplication> applications = volunteerService.getUserApplications(username);

            if (!applications.isEmpty()) {
                response.put("applicationHistory", applications);
            }
        }

        return ResponseEntity.ok(response);
    }

    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    @PutMapping("/applications/{id}/approve")
    public ResponseEntity<?> approveVolunteerApplication(@PathVariable Long id) {
        try {
            VolunteerApplication application = volunteerService.approveApplication(id);
            return ResponseEntity.ok(application);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error approving application: " + e.getMessage());
        }
    }

    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    @PutMapping("/applications/{id}/reject")
    public ResponseEntity<?> rejectVolunteerApplication(
            @PathVariable Long id,
            @RequestParam(required = false) String reason) {

        try {
            VolunteerApplication application = volunteerService.rejectApplication(id, reason);
            return ResponseEntity.ok(application);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Error rejecting application: " + e.getMessage());
        }
    }

    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    @GetMapping("/applications/status/{status}")
    public ResponseEntity<List<VolunteerApplication>> getApplicationsByStatus(
            @PathVariable String status) {

        List<VolunteerApplication> applications = volunteerService.getApplicationsByStatus(status);
        return ResponseEntity.ok(applications);
    }
}
