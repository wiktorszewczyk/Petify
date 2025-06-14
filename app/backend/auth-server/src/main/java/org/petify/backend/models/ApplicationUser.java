package org.petify.backend.models;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonManagedReference;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.Lob;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import jakarta.persistence.Version;
import lombok.Getter;
import lombok.Setter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.HashSet;
import java.util.Set;

@Getter
@Setter
@Entity
@Table(name = "users")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class ApplicationUser implements UserDetails {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer userId;

    @Column(unique = true)
    private String username;

    private String password;

    @Column(name = "first_name")
    private String firstName;

    @Column(name = "last_name")
    private String lastName;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "gender")
    private String gender;

    @Column(name = "phone_number", unique = true)
    private String phoneNumber;

    @Column(name = "email", unique = true)
    private String email;

    @Enumerated(EnumType.STRING)
    @Column(name = "volunteer_status")
    private VolunteerStatus volunteerStatus = VolunteerStatus.NONE;

    @Column(name = "active")
    private boolean active = true;

    @Column(name = "deactivation_reason")
    private String deactivationReason;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "xp_points")
    private Integer xpPoints = 0;

    @Column(name = "level")
    private Integer level = 1;

    @Column(name = "likes_count")
    private Integer likesCount = 0;

    @Column(name = "support_count")
    private Integer supportCount = 0;

    @Column(name = "badges_count")
    private Integer badgesCount = 0;

    @Column(name = "adoption_count")
    private Integer adoptionCount = 0;

    @Column(name = "city")
    private String city;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    @Column(name = "preferred_search_distance_km")
    private Double preferredSearchDistanceKm = 20.0;

    @Column(name = "auto_location_enabled")
    private Boolean autoLocationEnabled = false;

    @Column(name = "location_updated_at")
    private LocalDateTime locationUpdatedAt;

    @Column(name = "profile_image")
    @Lob
    @JsonIgnore
    private byte[] profileImage;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference
    private Set<UserAchievement> achievements = new HashSet<>();

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
            name = "user_role_junction",
            joinColumns = {@JoinColumn(name = "user_id")},
            inverseJoinColumns = {@JoinColumn(name = "role_id")}
    )
    private Set<Role> authorities;

    @Version
    private Integer version = 0;

    @Transient
    public Integer getXpToNextLevel() {
        int currentLevel = this.level != null ? this.level : 1;
        int currentXp = this.xpPoints != null ? this.xpPoints : 0;

        int xpRequiredForNextLevel = currentLevel * 100;

        return Math.max(0, xpRequiredForNextLevel - currentXp);
    }

    @Transient
    public boolean hasLocation() {
        return latitude != null && longitude != null;
    }

    @Transient
    public boolean hasCompleteLocationProfile() {
        return city != null && !city.trim().isEmpty() && hasLocation();
    }

    @Transient
    @JsonProperty("hasProfileImage")
    public boolean hasProfileImage() {
        try {
            return profileImage != null && profileImage.length > 0;
        } catch (Exception e) {
            return false;
        }
    }

    public void setLocation(String city, Double latitude, Double longitude) {
        this.city = city;
        this.latitude = latitude;
        this.longitude = longitude;
        this.locationUpdatedAt = LocalDateTime.now();
    }

    public void clearLocation() {
        this.city = null;
        this.latitude = null;
        this.longitude = null;
        this.locationUpdatedAt = null;
    }

    public ApplicationUser() {
        super();
        authorities = new HashSet<>();
    }

    public ApplicationUser(Integer userId, String username, String password,
                           String firstName, String lastName, LocalDate birthDate,
                           String gender, String phoneNumber, String email, Set<Role> authorities) {
        super();
        this.userId = userId;
        this.username = username;
        this.password = password;
        this.firstName = firstName;
        this.lastName = lastName;
        this.birthDate = birthDate;
        this.gender = gender;
        this.phoneNumber = phoneNumber;
        this.email = email;
        this.authorities = authorities;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return this.authorities;
    }

    @Override
    public String getPassword() {
        return this.password;
    }

    @Override
    public String getUsername() {
        return this.username;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }
}
