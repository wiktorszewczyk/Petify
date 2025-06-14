package org.petify.backend.dto;

import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.Role;
import org.petify.backend.models.UserAchievement;
import org.petify.backend.models.VolunteerStatus;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;

@Getter
@Setter
public class UserResponseDTO {
    private Integer userId;
    private String username;
    private String firstName;
    private String lastName;
    private LocalDate birthDate;
    private String gender;
    private String phoneNumber;
    private String email;
    private VolunteerStatus volunteerStatus;
    private boolean active;
    private LocalDateTime createdAt;
    private Integer xpPoints;
    private Integer level;
    private Integer likesCount;
    private Integer supportCount;
    private Integer badgesCount;
    private String city;
    private Double latitude;
    private Double longitude;
    private Double preferredSearchDistanceKm;
    private Boolean autoLocationEnabled;
    private LocalDateTime locationUpdatedAt;
    private boolean hasProfileImage;
    private Set<Role> authorities;
    private Integer version;

    private Set<UserAchievement> achievements;

    private Integer xpToNextLevel;
    private boolean hasLocation;
    private boolean hasCompleteLocationProfile;

    public UserResponseDTO() {}

    public UserResponseDTO(ApplicationUser user) {
        this.userId = user.getUserId();
        this.username = user.getUsername();
        this.firstName = user.getFirstName();
        this.lastName = user.getLastName();
        this.birthDate = user.getBirthDate();
        this.gender = user.getGender();
        this.phoneNumber = user.getPhoneNumber();
        this.email = user.getEmail();
        this.volunteerStatus = user.getVolunteerStatus();
        this.active = user.isActive();
        this.createdAt = user.getCreatedAt();
        this.xpPoints = user.getXpPoints();
        this.level = user.getLevel();
        this.likesCount = user.getLikesCount();
        this.supportCount = user.getSupportCount();
        this.badgesCount = user.getBadgesCount();
        this.city = user.getCity();
        this.latitude = user.getLatitude();
        this.longitude = user.getLongitude();
        this.preferredSearchDistanceKm = user.getPreferredSearchDistanceKm();
        this.autoLocationEnabled = user.getAutoLocationEnabled();
        this.locationUpdatedAt = user.getLocationUpdatedAt();
        this.hasProfileImage = user.hasProfileImage();

        this.authorities = user.getAuthorities() != null
                ? user.getAuthorities().stream()
                        .filter(Role.class::isInstance)
                        .map(Role.class::cast)
                        .collect(Collectors.toSet()) :
                new HashSet<>();

        this.achievements = user.getAchievements() != null
                ? user.getAchievements() : new HashSet<>();

        this.version = user.getVersion();

        this.xpToNextLevel = user.getXpToNextLevel();
        this.hasLocation = user.hasLocation();
        this.hasCompleteLocationProfile = user.hasCompleteLocationProfile();
    }

    public static UserResponseDTO fromUser(ApplicationUser user) {
        return new UserResponseDTO(user);
    }
}
