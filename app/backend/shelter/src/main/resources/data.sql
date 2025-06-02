-- Dodanie użytkowników
INSERT INTO users (
    active,
    badges_count,
    birth_date,
    created_at,
    deactivation_reason,
    email,
    first_name,
    gender,
    last_name,
    level,
    likes_count,
    password,
    phone_number,
    support_count,
    username,
    version,
    volunteer_status,
    xp_points
) VALUES
      (
          true, 0, '2000-01-01', '2025-06-01 10:59:52.612417', NULL,
          'shelter1@example.com', 'Shelter', NULL, 'One', 5, 0,
          (SELECT password FROM users WHERE user_id = 1),
          NULL, 0, 'shelter1', 1, 'NONE', 500
      ),
      (
          true, 0, '2000-01-01', '2025-06-01 10:59:52.612417', NULL,
          'shelter2@example.com', 'Shelter', NULL, 'Two', 5, 0,
          (SELECT password FROM users WHERE user_id = 1),
          NULL, 0, 'shelter2', 1, 'NONE', 500
      ),
      (
          true, 0, '2000-01-01', '2025-06-01 10:59:52.612417', NULL,
          'user1@example.com', 'User', NULL, 'One', 5, 0,
          (SELECT password FROM users WHERE user_id = 1),
          NULL, 0, 'user1', 1, 'NONE', 500
      );

-- haslo do kazdego konta to admin

INSERT INTO user_role_junction (user_id, role_id)
VALUES
    ((SELECT user_id FROM users WHERE username = 'shelter1'), 4),
    ((SELECT user_id FROM users WHERE username = 'shelter2'), 4),
    ((SELECT user_id FROM users WHERE username = 'user1'), 2);

-- Tworzymy schroniska
INSERT INTO shelters (
    address,
    description,
    is_active,
    latitude,
    longitude,
    name,
    owner_username,
    phone_number
) VALUES
      (
          'ul. Leśna 10, Warszawa',
          'Schronisko dla zwierząt w Warszawie',
          true,
          52.2297,
          21.0122,
          'Schronisko Warszawa',
          'shelter1',
          '+48123456789'
      ),
      (
          'ul. Polna 5, Kraków',
          'Schronisko dla zwierząt w Krakowie',
          true,
          50.0647,
          19.9450,
          'Schronisko Kraków',
          'shelter2',
          '+48198765432'
      );

-- Zwierzaki przypisane do schroniska o owner_username = 'shelter1'
INSERT INTO pets (
    age,
    is_archived,
    breed,
    description,
    gender,
    image_data,
    image_name,
    image_extension,
    is_kid_friendly,
    name,
    size,
    is_sterilized,
    type,
    is_urgent,
    is_vaccinated,
    shelter_id
) VALUES
      (
          2, false, 'Owczarek niemiecki', 'Przyjazny i energiczny pies.', 'MALE', NULL, NULL, NULL, true, 'Max', 'BIG', true, 'DOG', false, true,
          (SELECT id FROM shelters WHERE owner_username = 'shelter1')
      ),
      (
          1, false, 'Kot perski', 'Łagodny kot.', 'FEMALE', NULL, NULL, NULL, true, 'Luna', 'SMALL', true, 'CAT', false, true,
          (SELECT id FROM shelters WHERE owner_username = 'shelter1')
      ),
      (
          4, false, 'Królik europejski', 'Idealny do domu z dziećmi.', 'FEMALE', NULL, NULL, NULL, true, 'Bunny', 'SMALL', false, 'OTHER', false, false,
          (SELECT id FROM shelters WHERE owner_username = 'shelter1')
      );

-- Zwierzaki przypisane do schroniska o owner_username = 'shelter2'
INSERT INTO pets (
    age,
    is_archived,
    breed,
    description,
    gender,
    image_data,
    image_name,
    image_extension,
    is_kid_friendly,
    name,
    size,
    is_sterilized,
    type,
    is_urgent,
    is_vaccinated,
    shelter_id
) VALUES
      (
          3, false, 'Beagle', 'Aktywny i przyjazny pies.', 'MALE', NULL, NULL, NULL, true, 'Rocky', 'MEDIUM', true, 'DOG', true, true,
          (SELECT id FROM shelters WHERE owner_username = 'shelter2')
      ),
      (
          2, false, 'Kot dachowiec', 'Niezależny kot.', 'FEMALE', NULL, NULL, NULL, false, 'Mila', 'SMALL', false, 'CAT', false, false,
          (SELECT id FROM shelters WHERE owner_username = 'shelter2')
      ),
      (
          1, false, 'Kot brytyjski', 'Elegancki.', 'FEMALE', NULL, NULL, NULL, false, 'Kiki', 'SMALL', true, 'CAT', false, true,
          (SELECT id FROM shelters WHERE owner_username = 'shelter2')
      ),
      (
          5, false, 'Świnka morska', 'Łagodna i cicha.', 'MALE', NULL, NULL, NULL, true, 'Porky', 'SMALL', false, 'OTHER', false, true,
          (SELECT id FROM shelters WHERE owner_username = 'shelter2')
      );
