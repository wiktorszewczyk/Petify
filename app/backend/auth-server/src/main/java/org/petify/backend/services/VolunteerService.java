package org.petify.backend.services;

import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.VolunteerApplication;
import org.petify.backend.models.VolunteerStatus;
import org.petify.backend.repository.UserRepository;
import org.petify.backend.repository.VolunteerApplicationRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class VolunteerService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private VolunteerApplicationRepository volunteerApplicationRepository;

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
