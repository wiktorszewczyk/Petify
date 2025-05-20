package org.petify.backend;

import org.petify.backend.models.Achievement;
import org.petify.backend.models.AchievementCategory;
import org.petify.backend.models.ApplicationUser;
import org.petify.backend.models.Role;
import org.petify.backend.repository.AchievementRepository;
import org.petify.backend.repository.RoleRepository;
import org.petify.backend.repository.UserRepository;
import org.petify.backend.services.AchievementService;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.HashSet;
import java.util.Set;

@SpringBootApplication
public class AuthServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(AuthServerApplication.class, args);
    }

    @Bean
    CommandLineRunner run(
            RoleRepository roleRepository,
            UserRepository userRepository,
            AchievementRepository achievementRepository,
            AchievementService achievementService,
            PasswordEncoder passwordEncoder) {
        return args -> {
            boolean needToInitRoles = !roleRepository.findByAuthority("ADMIN").isPresent();

            if (needToInitRoles) {
                System.out.println("Inicjalizacja ról...");
                final Role adminRole = roleRepository.save(new Role("ADMIN"));
                roleRepository.save(new Role("USER"));
                roleRepository.save(new Role("VOLUNTEER"));
                roleRepository.save(new Role("SHELTER"));

                Set<Role> adminRoles = new HashSet<>();
                adminRoles.add(adminRole);

                ApplicationUser admin = new ApplicationUser();
                admin.setUsername("admin");
                admin.setPassword(passwordEncoder.encode("admin"));
                admin.setEmail("admin@petify.org");
                admin.setFirstName("Admin");
                admin.setLastName("User");
                admin.setAuthorities(adminRoles);

                // Set XP and level for admin
                admin.setXpPoints(500);
                admin.setLevel(5);
                admin.setLikesCount(0);
                admin.setSupportCount(0);
                admin.setBadgesCount(0);

                ApplicationUser savedAdmin = userRepository.save(admin);

                // Initialize achievements for admin user
                achievementService.initializeUserAchievements(savedAdmin);
            }

            long achievementCount = achievementRepository.count();
            if (achievementCount == 0) {
                System.out.println("Inicjalizacja osiągnięć...");

                // LIKES category achievements
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

                // SUPPORT category achievements
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
                achievement6.setXpReward(200);
                achievement6.setCategory(AchievementCategory.SUPPORT);
                achievement6.setRequiredActions(25);
                achievementRepository.save(achievement6);

                // BADGE category achievements
                Achievement achievement7 = new Achievement();
                achievement7.setName("Wirtualny opiekun");
                achievement7.setDescription("Wspieraj wybranego zwierzaka przez 5 kolejnych dni");
                achievement7.setIconName("pet");
                achievement7.setXpReward(100);
                achievement7.setCategory(AchievementCategory.BADGE);
                achievement7.setRequiredActions(5);
                achievementRepository.save(achievement7);

                Achievement achievement8 = new Achievement();
                achievement8.setName("Charytatywna dusza");
                achievement8.setDescription("Wpłać łączną sumę darowizn na sumę 100 zł");
                achievement8.setIconName("money-bill");
                achievement8.setXpReward(150);
                achievement8.setCategory(AchievementCategory.BADGE);
                achievement8.setRequiredActions(100);
                achievementRepository.save(achievement8);

                System.out.println("Osiągnięcia zainicjalizowane pomyślnie");
            }
        };
    }
}
