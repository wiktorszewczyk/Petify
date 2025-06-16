package org.petify.backend.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.Role;
import org.petify.backend.models.VolunteerApplication;
import org.petify.backend.models.VolunteerStatus;
import org.petify.backend.repository.RoleRepository;
import org.petify.backend.repository.UserRepository;
import org.petify.backend.repository.VolunteerApplicationRepository;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class VolunteerServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private VolunteerApplicationRepository volunteerApplicationRepository;

    @Mock
    private RoleRepository roleRepository;

    @Mock
    private VolunteerAchievementService volunteerAchievementService;

    @InjectMocks
    private VolunteerService volunteerService;

    private ApplicationUser testUser;
    private VolunteerApplication testApplication;
    private Role userRole;
    private Role volunteerRole;

    @BeforeEach
    void setUp() {
        userRole = new Role();
        userRole.setAuthority("USER");

        volunteerRole = new Role();
        volunteerRole.setAuthority("VOLUNTEER");

        testUser = new ApplicationUser();
        testUser.setUsername("testuser");
        testUser.setVolunteerStatus(VolunteerStatus.NONE);
        testUser.setAuthorities(Set.of(userRole));

        testApplication = new VolunteerApplication();
        testApplication.setUser(testUser);
        testApplication.setMotivation("I love helping animals");
        testApplication.setExperience("5 years with dogs");
        testApplication.setAvailability("Weekends");
        testApplication.setStatus("PENDING");
        testApplication.setApplicationDate(LocalDateTime.now());
    }

    @Test
    void applyForVolunteer_WhenUserHasNoVolunteerStatus_ShouldCreateApplication() {
        VolunteerApplication newApplication = new VolunteerApplication();
        newApplication.setMotivation("I love helping animals");
        newApplication.setExperience("5 years with dogs");
        newApplication.setAvailability("Weekends");

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);
        when(volunteerApplicationRepository.save(any(VolunteerApplication.class))).thenReturn(testApplication);

        VolunteerApplication result = volunteerService.applyForVolunteer("testuser", newApplication);

        assertThat(result).isNotNull();
        assertThat(result.getUser()).isEqualTo(testUser);
        assertThat(result.getStatus()).isEqualTo("PENDING");
        assertThat(result.getApplicationDate()).isNotNull();
        assertThat(testUser.getVolunteerStatus()).isEqualTo(VolunteerStatus.PENDING);

        verify(userRepository).save(testUser);
        verify(volunteerApplicationRepository).save(any(VolunteerApplication.class));
        verify(volunteerAchievementService).onVolunteerApplicationSubmitted("testuser");
    }

    @Test
    void applyForVolunteer_WhenUserNotFound_ShouldThrowException() {
        VolunteerApplication newApplication = new VolunteerApplication();
        when(userRepository.findByUsername("nonexistent")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> volunteerService.applyForVolunteer("nonexistent", newApplication))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("User not found");

        verify(volunteerApplicationRepository, never()).save(any(VolunteerApplication.class));
        verify(volunteerAchievementService, never()).onVolunteerApplicationSubmitted(anyString());
    }

    @Test
    void applyForVolunteer_WhenUserAlreadyHasVolunteerStatus_ShouldThrowException() {
        testUser.setVolunteerStatus(VolunteerStatus.PENDING);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));

        VolunteerApplication newApplication = new VolunteerApplication();

        assertThatThrownBy(() -> volunteerService.applyForVolunteer("testuser", newApplication))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("User already has a volunteer status: PENDING");

        verify(volunteerApplicationRepository, never()).save(any(VolunteerApplication.class));
        verify(volunteerAchievementService, never()).onVolunteerApplicationSubmitted(anyString());
    }

    @Test
    void getUserApplications_WhenUserExists_ShouldReturnUserApplications() {
        List<VolunteerApplication> expectedApplications = List.of(testApplication);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(volunteerApplicationRepository.findByUserOrderByApplicationDateDesc(testUser))
                .thenReturn(expectedApplications);

        List<VolunteerApplication> result = volunteerService.getUserApplications("testuser");

        assertThat(result).isEqualTo(expectedApplications);
        verify(userRepository).findByUsername("testuser");
        verify(volunteerApplicationRepository).findByUserOrderByApplicationDateDesc(testUser);
    }

    @Test
    void getUserApplications_WhenUserNotFound_ShouldThrowException() {
        when(userRepository.findByUsername("nonexistent")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> volunteerService.getUserApplications("nonexistent"))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("User not found");
    }

    @Test
    void approveApplication_WhenApplicationExists_ShouldApproveAndAddVolunteerRole() {
        testApplication.setId(1L);
        when(volunteerApplicationRepository.findById(1L)).thenReturn(Optional.of(testApplication));
        when(roleRepository.findByAuthority("VOLUNTEER")).thenReturn(Optional.of(volunteerRole));
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);
        when(volunteerApplicationRepository.save(any(VolunteerApplication.class))).thenReturn(testApplication);

        VolunteerApplication result = volunteerService.approveApplication(1L);

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("APPROVED");
        assertThat(result.getProcessedDate()).isNotNull();
        assertThat(testUser.getVolunteerStatus()).isEqualTo(VolunteerStatus.ACTIVE);

        Set<Role> authorities = (Set<Role>) testUser.getAuthorities();
        assertThat(authorities).anySatisfy(role ->
                assertThat(role.getAuthority()).isEqualTo("VOLUNTEER"));

        verify(userRepository).save(testUser);
        verify(volunteerApplicationRepository).save(testApplication);
        verify(volunteerAchievementService).onVolunteerApproved("testuser");
    }

    @Test
    void approveApplication_WhenApplicationNotFound_ShouldThrowException() {
        when(volunteerApplicationRepository.findById(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> volunteerService.approveApplication(1L))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Application not found");

        verify(userRepository, never()).save(any(ApplicationUser.class));
        verify(volunteerAchievementService, never()).onVolunteerApproved(anyString());
    }

    @Test
    void approveApplication_WhenVolunteerRoleNotFound_ShouldThrowException() {
        testApplication.setId(1L);
        when(volunteerApplicationRepository.findById(1L)).thenReturn(Optional.of(testApplication));
        when(roleRepository.findByAuthority("VOLUNTEER")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> volunteerService.approveApplication(1L))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("VOLUNTEER role not found");

        verify(userRepository, never()).save(any(ApplicationUser.class));
        verify(volunteerAchievementService, never()).onVolunteerApproved(anyString());
    }

    @Test
    void rejectApplication_WhenApplicationExists_ShouldRejectAndRemoveVolunteerRole() {
        Set<Role> userRoles = new HashSet<>();
        userRoles.add(userRole);
        userRoles.add(volunteerRole);
        testUser.setAuthorities(userRoles);

        testApplication.setId(1L);
        when(volunteerApplicationRepository.findById(1L)).thenReturn(Optional.of(testApplication));
        when(roleRepository.findByAuthority("VOLUNTEER")).thenReturn(Optional.of(volunteerRole));
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);
        when(volunteerApplicationRepository.save(any(VolunteerApplication.class))).thenReturn(testApplication);

        VolunteerApplication result = volunteerService.rejectApplication(1L, "Insufficient experience");

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("REJECTED");
        assertThat(result.getRejectionReason()).isEqualTo("Insufficient experience");
        assertThat(result.getProcessedDate()).isNotNull();
        assertThat(testUser.getVolunteerStatus()).isEqualTo(VolunteerStatus.INACTIVE);

        Set<Role> authorities = (Set<Role>) testUser.getAuthorities();
        assertThat(authorities).noneSatisfy(role ->
                assertThat(role.getAuthority()).isEqualTo("VOLUNTEER"));

        verify(userRepository).save(testUser);
        verify(volunteerApplicationRepository).save(testApplication);
    }

    @Test
    void rejectApplication_WhenApplicationNotFound_ShouldThrowException() {
        when(volunteerApplicationRepository.findById(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> volunteerService.rejectApplication(1L, "Reason"))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Application not found");

        verify(userRepository, never()).save(any(ApplicationUser.class));
        verify(volunteerApplicationRepository, never()).save(any(VolunteerApplication.class));
    }

    @Test
    void rejectApplication_WhenVolunteerRoleNotFound_ShouldStillRejectApplication() {
        testApplication.setId(1L);
        when(volunteerApplicationRepository.findById(1L)).thenReturn(Optional.of(testApplication));
        when(roleRepository.findByAuthority("VOLUNTEER")).thenReturn(Optional.empty());
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);
        when(volunteerApplicationRepository.save(any(VolunteerApplication.class))).thenReturn(testApplication);

        VolunteerApplication result = volunteerService.rejectApplication(1L, "Insufficient experience");

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("REJECTED");
        assertThat(result.getRejectionReason()).isEqualTo("Insufficient experience");
        assertThat(testUser.getVolunteerStatus()).isEqualTo(VolunteerStatus.INACTIVE);

        verify(userRepository).save(testUser);
        verify(volunteerApplicationRepository).save(testApplication);
    }

    @Test
    void getApplicationsByStatus_ShouldReturnApplicationsWithGivenStatus() {
        List<VolunteerApplication> expectedApplications = List.of(testApplication);
        when(volunteerApplicationRepository.findByStatus("PENDING")).thenReturn(expectedApplications);

        List<VolunteerApplication> result = volunteerService.getApplicationsByStatus("PENDING");

        assertThat(result).isEqualTo(expectedApplications);
        verify(volunteerApplicationRepository).findByStatus("PENDING");
    }

    @Test
    void getApplicationsByStatus_WhenNoApplicationsFound_ShouldReturnEmptyList() {
        when(volunteerApplicationRepository.findByStatus("APPROVED")).thenReturn(List.of());

        List<VolunteerApplication> result = volunteerService.getApplicationsByStatus("APPROVED");

        assertThat(result).isEmpty();
        verify(volunteerApplicationRepository).findByStatus("APPROVED");
    }

    @Test
    void approveApplication_ShouldMaintainExistingRoles() {
        Role adminRole = new Role();
        adminRole.setAuthority("ADMIN");

        Set<Role> existingRoles = new HashSet<>();
        existingRoles.add(userRole);
        existingRoles.add(adminRole);
        testUser.setAuthorities(existingRoles);

        testApplication.setId(1L);
        when(volunteerApplicationRepository.findById(1L)).thenReturn(Optional.of(testApplication));
        when(roleRepository.findByAuthority("VOLUNTEER")).thenReturn(Optional.of(volunteerRole));
        when(userRepository.save(any(ApplicationUser.class))).thenReturn(testUser);
        when(volunteerApplicationRepository.save(any(VolunteerApplication.class))).thenReturn(testApplication);

        VolunteerApplication result = volunteerService.approveApplication(1L);

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo("APPROVED");
        assertThat(testUser.getVolunteerStatus()).isEqualTo(VolunteerStatus.ACTIVE);

        Set<Role> authorities = (Set<Role>) testUser.getAuthorities();
        assertThat(authorities).hasSize(3);
        assertThat(authorities).anySatisfy(role ->
                assertThat(role.getAuthority()).isEqualTo("USER"));
        assertThat(authorities).anySatisfy(role ->
                assertThat(role.getAuthority()).isEqualTo("ADMIN"));
        assertThat(authorities).anySatisfy(role ->
                assertThat(role.getAuthority()).isEqualTo("VOLUNTEER"));

        verify(userRepository).save(testUser);
        verify(volunteerApplicationRepository).save(testApplication);
        verify(volunteerAchievementService).onVolunteerApproved("testuser");
    }
}
