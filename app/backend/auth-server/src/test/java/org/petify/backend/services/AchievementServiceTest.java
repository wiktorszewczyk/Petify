package org.petify.backend.services;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.petify.backend.models.Achievement;
import org.petify.backend.models.AchievementCategory;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.UserAchievement;
import org.petify.backend.repository.AchievementRepository;
import org.petify.backend.repository.UserAchievementRepository;
import org.petify.backend.repository.UserRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AchievementServiceTest {

    @Mock
    private AchievementRepository achievementRepository;

    @Mock
    private UserAchievementRepository userAchievementRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private AchievementService achievementService;

    private ApplicationUser testUser;
    private Achievement testAchievement;
    private UserAchievement testUserAchievement;

    @BeforeEach
    void setUp() {
        testUser = new ApplicationUser();
        testUser.setUserId(1);
        testUser.setUsername("testuser");
        testUser.setXpPoints(0);
        testUser.setLevel(1);
        testUser.setLikesCount(0);
        testUser.setSupportCount(0);
        testUser.setBadgesCount(0);
        testUser.setAdoptionCount(0);

        testAchievement = new Achievement();
        testAchievement.setId(1L);
        testAchievement.setName("First Like");
        testAchievement.setDescription("Give your first like");
        testAchievement.setCategory(AchievementCategory.LIKES);
        testAchievement.setRequiredActions(1);
        testAchievement.setXpReward(50);

        testUserAchievement = new UserAchievement();
        testUserAchievement.setId(1L);
        testUserAchievement.setUser(testUser);
        testUserAchievement.setAchievement(testAchievement);
        testUserAchievement.setCurrentProgress(0);
        testUserAchievement.setCompleted(false);
    }

    @Test
    void getUserAchievements_WhenUserExists_ShouldReturnUserAchievements() {
        List<UserAchievement> expectedAchievements = List.of(testUserAchievement);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(userAchievementRepository.findByUser(testUser)).thenReturn(expectedAchievements);

        List<UserAchievement> result = achievementService.getUserAchievements("testuser");

        assertThat(result).isEqualTo(expectedAchievements);
        verify(userRepository).findByUsername("testuser");
        verify(userAchievementRepository).findByUser(testUser);
    }

    @Test
    void getUserAchievements_WhenUserNotFound_ShouldThrowException() {
        when(userRepository.findByUsername("nonexistent")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> achievementService.getUserAchievements("nonexistent"))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("User not found");
    }

    @Test
    void trackAchievementProgress_WhenNewAchievementProgress_ShouldCreateAndSaveUserAchievement() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(achievementRepository.findById(1L)).thenReturn(Optional.of(testAchievement));
        when(userAchievementRepository.findByUserAndAchievementId(testUser, 1L)).thenReturn(Optional.empty());
        when(userAchievementRepository.save(any(UserAchievement.class))).thenReturn(testUserAchievement);

        UserAchievement result = achievementService.trackAchievementProgress("testuser", 1L, 1);

        assertThat(result).isNotNull();
        verify(userAchievementRepository).save(any(UserAchievement.class));
    }

    @Test
    void trackAchievementProgress_WhenAchievementCompleted_ShouldUpdateUserStatsAndLevel() {
        testUserAchievement.setCurrentProgress(0);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(achievementRepository.findById(1L)).thenReturn(Optional.of(testAchievement));
        when(userAchievementRepository.findByUserAndAchievementId(testUser, 1L)).thenReturn(Optional.of(testUserAchievement));
        when(userAchievementRepository.save(any(UserAchievement.class))).thenReturn(testUserAchievement);

        UserAchievement result = achievementService.trackAchievementProgress("testuser", 1L, 1);

        assertThat(result.getCompleted()).isTrue();
        assertThat(result.getCompletionDate()).isNotNull();
        assertThat(testUser.getXpPoints()).isEqualTo(50);
        assertThat(testUser.getLikesCount()).isEqualTo(1);
        verify(userRepository).save(testUser);
    }

    @Test
    void trackAchievementProgress_WhenAlreadyCompleted_ShouldReturnExistingAchievement() {
        testUserAchievement.setCompleted(true);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(achievementRepository.findById(1L)).thenReturn(Optional.of(testAchievement));
        when(userAchievementRepository.findByUserAndAchievementId(testUser, 1L)).thenReturn(Optional.of(testUserAchievement));

        UserAchievement result = achievementService.trackAchievementProgress("testuser", 1L, 1);

        assertThat(result).isEqualTo(testUserAchievement);
        verify(userAchievementRepository, never()).save(any(UserAchievement.class));
        verify(userRepository, never()).save(any(ApplicationUser.class));
    }

    @Test
    void trackAchievementProgress_WhenUserNotFound_ShouldThrowException() {
        when(userRepository.findByUsername("nonexistent")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> achievementService.trackAchievementProgress("nonexistent", 1L, 1))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("User not found");
    }

    @Test
    void trackAchievementProgress_WhenAchievementNotFound_ShouldThrowException() {
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(achievementRepository.findById(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> achievementService.trackAchievementProgress("testuser", 1L, 1))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("Achievement not found");
    }

    @Test
    void trackLikeAchievements_ShouldTrackAllLikeAchievements() {
        Achievement likeAchievement1 = new Achievement();
        likeAchievement1.setId(1L);
        likeAchievement1.setCategory(AchievementCategory.LIKES);

        Achievement likeAchievement2 = new Achievement();
        likeAchievement2.setId(2L);
        likeAchievement2.setCategory(AchievementCategory.LIKES);

        List<Achievement> likeAchievements = List.of(likeAchievement1, likeAchievement2);
        when(achievementRepository.findByCategory(AchievementCategory.LIKES)).thenReturn(likeAchievements);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(achievementRepository.findById(anyLong())).thenReturn(Optional.of(testAchievement));
        when(userAchievementRepository.findByUserAndAchievementId(any(), anyLong())).thenReturn(Optional.of(testUserAchievement));
        when(userAchievementRepository.save(any(UserAchievement.class))).thenReturn(testUserAchievement);

        achievementService.trackLikeAchievements("testuser");

        verify(achievementRepository).findByCategory(AchievementCategory.LIKES);
        verify(userRepository, times(2)).findByUsername("testuser");
    }

    @Test
    void trackSupportAchievements_ShouldTrackAllSupportAchievements() {
        Achievement supportAchievement = new Achievement();
        supportAchievement.setId(1L);
        supportAchievement.setCategory(AchievementCategory.SUPPORT);

        List<Achievement> supportAchievements = List.of(supportAchievement);
        when(achievementRepository.findByCategory(AchievementCategory.SUPPORT)).thenReturn(supportAchievements);

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(achievementRepository.findById(anyLong())).thenReturn(Optional.of(testAchievement));
        when(userAchievementRepository.findByUserAndAchievementId(any(), anyLong())).thenReturn(Optional.of(testUserAchievement));
        when(userAchievementRepository.save(any(UserAchievement.class))).thenReturn(testUserAchievement);

        achievementService.trackSupportAchievements("testuser");

        verify(achievementRepository).findByCategory(AchievementCategory.SUPPORT);
        verify(userRepository).findByUsername("testuser");
    }

    @Test
    void getUserLevelInfo_WhenUserExists_ShouldReturnLevelInfo() {
        testUser.setXpPoints(150);
        testUser.setLevel(2);
        testUser.setLikesCount(5);
        testUser.setSupportCount(3);
        testUser.setBadgesCount(2);
        testUser.setAdoptionCount(1);

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));

        Map<String, Object> result = achievementService.getUserLevelInfo("testuser");

        assertThat(result.get("level")).isEqualTo(2);
        assertThat(result.get("xpPoints")).isEqualTo(150);
        assertThat(result.get("likesCount")).isEqualTo(5);
        assertThat(result.get("supportCount")).isEqualTo(3);
        assertThat(result.get("badgesCount")).isEqualTo(2);
        assertThat(result.get("adoptionCount")).isEqualTo(1);
    }

    @Test
    void getUserLevelInfo_WhenUserNotFound_ShouldThrowException() {
        when(userRepository.findByUsername("nonexistent")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> achievementService.getUserLevelInfo("nonexistent"))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("User not found");
    }

    @Test
    void initializeUserAchievements_ShouldCreateUserAchievementsForAllAchievements() {
        Achievement achievement1 = new Achievement();
        achievement1.setId(1L);
        achievement1.setName("Achievement 1");

        Achievement achievement2 = new Achievement();
        achievement2.setId(2L);
        achievement2.setName("Achievement 2");

        List<Achievement> allAchievements = List.of(achievement1, achievement2);
        when(achievementRepository.findAll()).thenReturn(allAchievements);

        achievementService.initializeUserAchievements(testUser);

        verify(achievementRepository).findAll();
        verify(userAchievementRepository, times(2)).save(any(UserAchievement.class));
    }

    @Test
    void trackVolunteerAchievements_ShouldTrackAllVolunteerAchievements() {
        Achievement volunteerAchievement = new Achievement();
        volunteerAchievement.setId(1L);
        volunteerAchievement.setCategory(AchievementCategory.VOLUNTEER);

        List<Achievement> volunteerAchievements = List.of(volunteerAchievement);
        when(achievementRepository.findByCategory(AchievementCategory.VOLUNTEER)).thenReturn(volunteerAchievements);

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(achievementRepository.findById(anyLong())).thenReturn(Optional.of(testAchievement));
        when(userAchievementRepository.findByUserAndAchievementId(any(), anyLong())).thenReturn(Optional.of(testUserAchievement));
        when(userAchievementRepository.save(any(UserAchievement.class))).thenReturn(testUserAchievement);

        achievementService.trackVolunteerAchievements("testuser");

        verify(achievementRepository).findByCategory(AchievementCategory.VOLUNTEER);
        verify(userRepository).findByUsername("testuser");
    }

    @Test
    void trackAdoptionAchievements_ShouldTrackAllAdoptionAchievements() {
        Achievement adoptionAchievement = new Achievement();
        adoptionAchievement.setId(1L);
        adoptionAchievement.setCategory(AchievementCategory.ADOPTION);

        List<Achievement> adoptionAchievements = List.of(adoptionAchievement);
        when(achievementRepository.findByCategory(AchievementCategory.ADOPTION)).thenReturn(adoptionAchievements);

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(achievementRepository.findById(anyLong())).thenReturn(Optional.of(testAchievement));
        when(userAchievementRepository.findByUserAndAchievementId(any(), anyLong())).thenReturn(Optional.of(testUserAchievement));
        when(userAchievementRepository.save(any(UserAchievement.class))).thenReturn(testUserAchievement);

        achievementService.trackAdoptionAchievements("testuser");

        verify(achievementRepository).findByCategory(AchievementCategory.ADOPTION);
        verify(userRepository).findByUsername("testuser");
    }

    @Test
    void addExperiencePointsForDonation_WhenUserExists_ShouldAddXpAndUpdateLevel() {
        testUser.setXpPoints(80);
        testUser.setLevel(1);

        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));

        achievementService.addExperiencePointsForDonation("testuser", 30);

        assertThat(testUser.getXpPoints()).isEqualTo(110);
        assertThat(testUser.getLevel()).isEqualTo(2);
        verify(userRepository).save(testUser);
    }

    @Test
    void addExperiencePointsForDonation_WhenUserNotFound_ShouldThrowException() {
        when(userRepository.findByUsername("nonexistent")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> achievementService.addExperiencePointsForDonation("nonexistent", 50))
                .isInstanceOf(RuntimeException.class)
                .hasMessage("User not found");
    }

    @Test
    void trackProfileAchievementByName_ShouldTrackProfileAchievement() {
        Achievement profileAchievement = new Achievement();
        profileAchievement.setId(1L);
        profileAchievement.setName("Profile Complete");
        profileAchievement.setCategory(AchievementCategory.PROFILE);
        profileAchievement.setRequiredActions(1);
        profileAchievement.setXpReward(10);

        List<Achievement> profileAchievements = List.of(profileAchievement);
        when(achievementRepository.findByCategory(AchievementCategory.PROFILE)).thenReturn(profileAchievements);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(userAchievementRepository.findByUserAndAchievementId(testUser, 1L)).thenReturn(Optional.empty());
        when(achievementRepository.findById(1L)).thenReturn(Optional.of(profileAchievement));
        when(userAchievementRepository.save(any(UserAchievement.class))).thenReturn(testUserAchievement);

        achievementService.trackProfileAchievementByName("testuser", "Profile Complete");

        verify(achievementRepository).findByCategory(AchievementCategory.PROFILE);
        verify(userRepository, times(2)).findByUsername("testuser");
    }

    @Test
    void trackVolunteerAchievementByName_ShouldTrackVolunteerAchievement() {
        Achievement volunteerAchievement = new Achievement();
        volunteerAchievement.setId(1L);
        volunteerAchievement.setName("First Volunteer");
        volunteerAchievement.setCategory(AchievementCategory.VOLUNTEER);
        volunteerAchievement.setRequiredActions(1);
        volunteerAchievement.setXpReward(10);

        List<Achievement> volunteerAchievements = List.of(volunteerAchievement);
        when(achievementRepository.findByCategory(AchievementCategory.VOLUNTEER)).thenReturn(volunteerAchievements);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(userAchievementRepository.findByUserAndAchievementId(testUser, 1L)).thenReturn(Optional.empty());
        when(achievementRepository.findById(1L)).thenReturn(Optional.of(volunteerAchievement));
        when(userAchievementRepository.save(any(UserAchievement.class))).thenReturn(testUserAchievement);

        achievementService.trackVolunteerAchievementByName("testuser", "First Volunteer");

        verify(achievementRepository).findByCategory(AchievementCategory.VOLUNTEER);
        verify(userRepository, times(2)).findByUsername("testuser");
    }

    @Test
    void trackAchievementProgress_WhenLevelUpOccurs_ShouldUpdateUserLevel() {
        testUser.setXpPoints(95);
        testUser.setLevel(1);
        testAchievement.setXpReward(10);

        testUserAchievement.setCurrentProgress(0);
        when(userRepository.findByUsername("testuser")).thenReturn(Optional.of(testUser));
        when(achievementRepository.findById(1L)).thenReturn(Optional.of(testAchievement));
        when(userAchievementRepository.findByUserAndAchievementId(testUser, 1L)).thenReturn(Optional.of(testUserAchievement));
        when(userAchievementRepository.save(any(UserAchievement.class))).thenReturn(testUserAchievement);

        achievementService.trackAchievementProgress("testuser", 1L, 1);

        assertThat(testUser.getLevel()).isEqualTo(2);
        assertThat(testUser.getXpPoints()).isEqualTo(105);
        verify(userRepository).save(testUser);
    }
}
