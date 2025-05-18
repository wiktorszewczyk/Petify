package org.petify.backend.models;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "achievements")
@Getter
@Setter
public class Achievement {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "description")
    private String description;

    @Column(name = "category")
    @Enumerated(EnumType.STRING)
    private AchievementCategory category;

    @Column(name = "xp_reward")
    private Integer xpReward;

    @Column(name = "required_actions")
    private Integer requiredActions;

    @Column(name = "icon_name")
    private String iconName;
}