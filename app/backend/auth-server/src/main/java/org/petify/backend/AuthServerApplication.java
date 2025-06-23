package org.petify.backend;

import org.petify.backend.models.Achievement;
import org.petify.backend.models.AchievementCategory;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.Role;
import org.petify.backend.models.VolunteerStatus;
import org.petify.backend.repository.AchievementRepository;
import org.petify.backend.repository.RoleRepository;
import org.petify.backend.repository.UserRepository;
import org.petify.backend.services.AchievementService;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Optional;
import java.util.Set;

@SpringBootApplication
@EnableConfigurationProperties(AuthServerApplication.AdminProperties.class)
public class AuthServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(AuthServerApplication.class, args);
    }

    @ConfigurationProperties(prefix = "petify.admin.credentials")
    public record AdminProperties(String username, String password, String email) {}

    @Bean
    CommandLineRunner run(
            RoleRepository roleRepository,
            UserRepository userRepository,
            AchievementRepository achievementRepository,
            AchievementService achievementService,
            PasswordEncoder passwordEncoder,
            AdminProperties adminProperties) {
        return args -> {
            Role adminRole = roleRepository.findByAuthority("ADMIN")
                    .orElseGet(() -> roleRepository.save(new Role("ADMIN")));
            Role userRole = roleRepository.findByAuthority("USER")
                    .orElseGet(() -> roleRepository.save(new Role("USER")));

            roleRepository.findByAuthority("VOLUNTEER")
                    .orElseGet(() -> roleRepository.save(new Role("VOLUNTEER")));
            roleRepository.findByAuthority("SHELTER")
                    .orElseGet(() -> roleRepository.save(new Role("SHELTER")));

            Optional<ApplicationUser> existingAdmin = userRepository.findByUsername(adminProperties.username());
            if (existingAdmin.isEmpty()) {
                Set<Role> adminRoles = new HashSet<>();
                adminRoles.add(adminRole);
                adminRoles.add(userRole);

                ApplicationUser admin = new ApplicationUser();
                admin.setUsername(adminProperties.username());
                admin.setPassword(passwordEncoder.encode(adminProperties.password()));
                admin.setEmail(adminProperties.email());

                admin.setFirstName("Petify");
                admin.setLastName("Administrator");
                admin.setBirthDate(LocalDate.of(1980, 1, 1));
                admin.setGender("MALE");
                admin.setPhoneNumber("+48000000000");
                admin.setVolunteerStatus(VolunteerStatus.NONE);
                admin.setActive(true);
                admin.setCreatedAt(LocalDateTime.now());
                admin.setAuthorities(adminRoles);

                admin.setXpPoints(1000);
                admin.setLevel(10);
                admin.setLikesCount(0);
                admin.setSupportCount(0);
                admin.setBadgesCount(0);
                admin.setAdoptionCount(0);

                ApplicationUser savedAdmin = userRepository.save(admin);
                achievementService.initializeUserAchievements(savedAdmin);
            }

            long achievementCount = achievementRepository.count();
            if (achievementCount == 0) {
                Achievement achievement1 = new Achievement();
                achievement1.setName("Początkujący miłośnik");
                achievement1.setDescription("Polub 10 zwierząt");
                achievement1.setIconName("heart");
                achievement1.setXpReward(50);
                achievement1.setCategory(AchievementCategory.LIKES);
                achievement1.setRequiredActions(10);
                achievementRepository.save(achievement1);

                Achievement achievement2 = new Achievement();
                achievement2.setName("Entuzjastyczny miłośnik");
                achievement2.setDescription("Polub 50 zwierząt");
                achievement2.setIconName("heart");
                achievement2.setXpReward(100);
                achievement2.setCategory(AchievementCategory.LIKES);
                achievement2.setRequiredActions(50);
                achievementRepository.save(achievement2);

                Achievement achievement3 = new Achievement();
                achievement3.setName("Super miłośnik");
                achievement3.setDescription("Polub 100 zwierząt");
                achievement3.setIconName("heart");
                achievement3.setXpReward(200);
                achievement3.setCategory(AchievementCategory.LIKES);
                achievement3.setRequiredActions(100);
                achievementRepository.save(achievement3);

                Achievement achievement4 = new Achievement();
                achievement4.setName("Początkujące wsparcie");
                achievement4.setDescription("Wesprzyj 3 zwierzęta");
                achievement4.setIconName("hands-helping");
                achievement4.setXpReward(50);
                achievement4.setCategory(AchievementCategory.SUPPORT);
                achievement4.setRequiredActions(3);
                achievementRepository.save(achievement4);

                Achievement achievement5 = new Achievement();
                achievement5.setName("Entuzjastyczne wsparcie");
                achievement5.setDescription("Wesprzyj 10 zwierząt");
                achievement5.setIconName("hands-helping");
                achievement5.setXpReward(100);
                achievement5.setCategory(AchievementCategory.SUPPORT);
                achievement5.setRequiredActions(10);
                achievementRepository.save(achievement5);

                Achievement achievement6 = new Achievement();
                achievement6.setName("Super wsparcie");
                achievement6.setDescription("Wesprzyj 25 zwierząt");
                achievement6.setIconName("hands-helping");
                achievement6.setXpReward(250);
                achievement6.setCategory(AchievementCategory.SUPPORT);
                achievement6.setRequiredActions(25);
                achievementRepository.save(achievement6);

                Achievement profilePicture = new Achievement();
                profilePicture.setName("Pierwsza fotka");
                profilePicture.setDescription("Dodaj zdjęcie profilowe");
                profilePicture.setIconName("camera");
                profilePicture.setXpReward(50);
                profilePicture.setCategory(AchievementCategory.PROFILE);
                profilePicture.setRequiredActions(1);
                achievementRepository.save(profilePicture);

                Achievement completeProfile = new Achievement();
                completeProfile.setName("Kompletny profil");
                completeProfile.setDescription("Wypełnij wszystkie dane w profilu");
                completeProfile.setIconName("user-check");
                completeProfile.setXpReward(100);
                completeProfile.setCategory(AchievementCategory.PROFILE);
                completeProfile.setRequiredActions(1);
                achievementRepository.save(completeProfile);

                Achievement locationSet = new Achievement();
                locationSet.setName("Lokalizacja ustawiona");
                locationSet.setDescription("Dodaj swoją lokalizację");
                locationSet.setIconName("map-pin");
                locationSet.setXpReward(25);
                locationSet.setCategory(AchievementCategory.PROFILE);
                locationSet.setRequiredActions(1);
                achievementRepository.save(locationSet);

                Achievement volunteerAchievement = new Achievement();
                volunteerAchievement.setName("Ochotnik");
                volunteerAchievement.setDescription("Zgłoś się jako wolontariusz");
                volunteerAchievement.setIconName("hand-holding-heart");
                volunteerAchievement.setXpReward(75);
                volunteerAchievement.setCategory(AchievementCategory.VOLUNTEER);
                volunteerAchievement.setRequiredActions(1);
                achievementRepository.save(volunteerAchievement);

                Achievement firstAdoption = new Achievement();
                firstAdoption.setName("Pierwszy przyjaciel");
                firstAdoption.setDescription("Gratulacje za pierwszą adopcję zwierzęcia! Zmieniłeś czyjeś życie na lepsze.");
                firstAdoption.setIconName("heart-handshake");
                firstAdoption.setXpReward(200);
                firstAdoption.setCategory(AchievementCategory.ADOPTION);
                firstAdoption.setRequiredActions(1);
                achievementRepository.save(firstAdoption);

                Achievement animalRescuer = new Achievement();
                animalRescuer.setName("Ratownik zwierząt");
                animalRescuer.setDescription("Adoptowałeś już 5 zwierząt! Jesteś prawdziwym ratownikiem czworonogów.");
                animalRescuer.setIconName("shield-heart");
                animalRescuer.setXpReward(500);
                animalRescuer.setCategory(AchievementCategory.ADOPTION);
                animalRescuer.setRequiredActions(5);
                achievementRepository.save(animalRescuer);

                Achievement adoptionAngel = new Achievement();
                adoptionAngel.setName("Anioł adopcji");
                adoptionAngel.setDescription("Niesamowite! 10 adopcji za Tobą. Jesteś prawdziwym aniołem dla bezdomnych zwierząt.");
                adoptionAngel.setIconName("crown");
                adoptionAngel.setXpReward(1000);
                adoptionAngel.setCategory(AchievementCategory.ADOPTION);
                adoptionAngel.setRequiredActions(10);
                achievementRepository.save(adoptionAngel);
            }
        };
    }
}
