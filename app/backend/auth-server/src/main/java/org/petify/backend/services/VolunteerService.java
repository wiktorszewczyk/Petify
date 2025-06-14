package org.petify.backend.services;

import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.Role;
import org.petify.backend.models.VolunteerApplication;
import org.petify.backend.models.VolunteerStatus;
import org.petify.backend.repository.RoleRepository;
import org.petify.backend.repository.UserRepository;
import org.petify.backend.repository.VolunteerApplicationRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class VolunteerService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private VolunteerApplicationRepository volunteerApplicationRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Transactional
    public VolunteerApplication applyForVolunteer(String username, VolunteerApplication application) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (user.getVolunteerStatus() != VolunteerStatus.NONE) {
            throw new IllegalStateException("User already has a volunteer status: " + user.getVolunteerStatus());
        }

        user.setVolunteerStatus(VolunteerStatus.PENDING);
        userRepository.save(user);

        application.setUser(user);
        application.setApplicationDate(LocalDateTime.now());
        application.setStatus("PENDING");

        return volunteerApplicationRepository.save(application);
    }

    public List<VolunteerApplication> getUserApplications(String username) {
        ApplicationUser user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return volunteerApplicationRepository.findByUserOrderByApplicationDateDesc(user);
    }

    @Transactional
    public VolunteerApplication approveApplication(Long applicationId) {
        VolunteerApplication application = volunteerApplicationRepository.findById(applicationId)
                .orElseThrow(() -> new RuntimeException("Application not found"));

        ApplicationUser user = application.getUser();
        user.setVolunteerStatus(VolunteerStatus.ACTIVE);

        Role volunteerRole = roleRepository.findByAuthority("VOLUNTEER")
                .orElseThrow(() -> new RuntimeException("VOLUNTEER role not found"));
        
        Set<Role> userRoles = new HashSet<>((Set<Role>) user.getAuthorities());
        userRoles.add(volunteerRole);
        user.setAuthorities(userRoles);
        userRepository.save(user);

        application.setStatus("APPROVED");
        application.setProcessedDate(LocalDateTime.now());
        return volunteerApplicationRepository.save(application);
    }

    @Transactional
    public VolunteerApplication rejectApplication(Long applicationId, String reason) {
        VolunteerApplication application = volunteerApplicationRepository.findById(applicationId)
                .orElseThrow(() -> new RuntimeException("Application not found"));

        ApplicationUser user = application.getUser();
        user.setVolunteerStatus(VolunteerStatus.INACTIVE);
        
        Role volunteerRole = roleRepository.findByAuthority("VOLUNTEER").orElse(null);
        if (volunteerRole != null) {
            Set<Role> userRoles = new HashSet<>((Set<Role>) user.getAuthorities());
            userRoles.remove(volunteerRole);
            user.setAuthorities(userRoles);
        }
        userRepository.save(user);

        application.setStatus("REJECTED");
        application.setRejectionReason(reason);
        application.setProcessedDate(LocalDateTime.now());
        return volunteerApplicationRepository.save(application);
    }

    public List<VolunteerApplication> getApplicationsByStatus(String status) {
        return volunteerApplicationRepository.findByStatus(status);
    }
}
