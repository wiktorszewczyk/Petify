import 'dart:math';
import 'dart:async';
import '../models/pet_model.dart';

class PetService {
  // Symulacja opóźnienia sieci
  final int _simulatedDelayMs = 800;

  static final PetService _instance = PetService._internal();

  factory PetService() {
    return _instance;
  }

  PetService._internal();

  final Set<String> _likedPetIds = {};

  final List<PetModel> _demoPets = [
    PetModel(
      id: 'pet1',
      name: 'Wawel',
      age: 4,
      gender: 'male',
      breed: 'Owczarek niemiecki',
      size: 'large',
      description: 'Uwielbiam aportować i pływać w jeziorze.',
      imageUrl: 'assets/demo/wawel1.jpg',
      galleryImages: [
        'assets/demo/wawel2.jpg',
      ],
      distance: 2,
      isVaccinated: true,
      isNeutered: true,
      isChildFriendly: true,
      isUrgent: false,
      shelterId: 's1',
      shelterName: 'Łódzkie Schronisko',
      shelterAddress: 'ul. Piotrkowska 120, Łódź',
    ),
    PetModel(
      id: 'pet2',
      name: 'Misia',
      age: 1,
      gender: 'female',
      breed: 'Kundel',
      size: 'small',
      description: 'Młoda i odważna, uwielbia długie spacery.',
      imageUrl: 'assets/demo/misia1.jpg',
      galleryImages: [
        'assets/demo/misia2.jpg',
        'assets/demo/misia3.jpg',
      ],
      distance: 5,
      isVaccinated: true,
      isNeutered: false,
      isChildFriendly: true,
      isUrgent: true,
      shelterId: 's2',
      shelterName: 'Azyl Pod Sercem',
      shelterAddress: 'ul. Narutowicza 45, Łódź',
    ),
    PetModel(
      id: 'pet3',
      name: 'Blanka',
      age: 3,
      gender: 'female',
      breed: 'Dachowiec',
      size: 'medium',
      description: 'Spokojna kompanka do drzemek na kanapie.',
      imageUrl: 'assets/demo/blanka1.jpg',
      galleryImages: [
        'assets/demo/blanka2.jpg'
      ],
      distance: 7,
      isVaccinated: false,
      isNeutered: true,
      isChildFriendly: false,
      isUrgent: false,
      shelterId: 's3',
      shelterName: 'Fundacja Puszek',
      shelterAddress: 'ul. Kilińskiego 18, Łódź',
    ),
    PetModel(
      id: 'pet4',
      name: 'Samba',
      age: 4,
      gender: 'female',
      breed: 'Dachowiec',
      size: 'small',
      description: 'Pełna energii, szuka aktywnego domu.',
      imageUrl: 'assets/demo/samba1.jpg',
      galleryImages: [],
      distance: 10,
      isVaccinated: true,
      isNeutered: true,
      isChildFriendly: true,
      isUrgent: false,
      shelterId: 's4',
      shelterName: 'Dom Zwierzaka',
      shelterAddress: 'ul. Wólczańska 66, Łódź',
    ),
    PetModel(
      id: 'pet5',
      name: 'Pchełka',
      age: 1,
      gender: 'female',
      breed: 'Kundel',
      size: 'medium',
      description: 'Towarzyska i wesoła, lubi dzieci i inne zwierzaki.',
      imageUrl: 'assets/demo/pchelka1.jpg',
      galleryImages: [
        'assets/demo/pchelka2.jpg'
      ],
      distance: 12,
      isVaccinated: false,
      isNeutered: false,
      isChildFriendly: true,
      isUrgent: true,
      shelterId: 's5',
      shelterName: 'Przytulisko',
      shelterAddress: 'ul. Łagiewnicka 75, Łódź',
    ),
  ];

  // Pobieranie listy zwierząt (symulacja API)
  /// TODO: Implementacja API do pobierania zwierząt dla użytkownika
  Future<List<PetModel>> getPets() async {
    // // Losowy generator - symulacja różnych wyników z API
    // final random = Random();
    //
    // // Symulacja różnej liczby zwierząt
    // final petCount = random.nextInt(5) + 5;
    //
    // final names = [
    //   'Max', 'Luna', 'Bella', 'Reksio', 'Azor', 'Mruczek', 'Puszek',
    //   'Figa', 'Kora', 'Milo', 'Burek', 'Filemon', 'Pluto', 'Simba'
    // ];
    //
    // final dogBreeds = [
    //   'Labrador', 'Owczarek niemiecki', 'Golden retriever', 'Buldog',
    //   'Beagle', 'Husky', 'Jamnik', 'Mieszaniec', 'Pudel', 'Dalmatyńczyk'
    // ];
    //
    // final catBreeds = [
    //   'Dachowiec', 'Pers', 'Maine Coon', 'Ragdoll', 'Bengal',
    //   'Brytyjski krótkowłosy', 'Syberyjski', 'Sfinks', 'Syjamski', 'Norweski leśny'
    // ];
    //
    // final descriptions = [
    //   'Jestem bardzo przyjaznym zwierzakiem, który uwielbia się przytulać. Szukam domu, w którym będę mógł otrzymać dużo miłości i uwagi.',
    //   'Energiczny i radosny, uwielbiam zabawy na świeżym powietrzu. Idealnie pasuję do aktywnej rodziny.',
    //   'Jestem spokojnym towarzyszem, który najchętniej spędza czas drzemiąc w ciepłym kąciku. Nie sprawiam problemów i dobrze dogaduję się z innymi zwierzętami.',
    //   'Potrzebuję domu, w którym dostanę czas na adaptację. Z początku mogę być nieśmiały, ale szybko się otwieram, gdy poczuję się bezpiecznie.',
    //   'Jestem bardzo inteligentny i szybko się uczę. Potrzebuję stymulacji umysłowej i regularnych treningów.',
    //   'Uwielbiam dzieci i będę doskonałym towarzyszem zabaw. Mam dużo cierpliwości i jestem bardzo delikatny.',
    //   'Mam za sobą trudną przeszłość, ale nie straciłem wiary w ludzi. Szukam cierpliwego opiekuna, który pomoże mi odbudować zaufanie.',
    // ];
    //
    // final shelters = [
    //   {
    //     'name': 'Schronisko "Pod Dobrą Łapą"',
    //     'address': 'ul. Adopcyjna 15, Warszawa',
    //   },
    //   {
    //     'name': 'Azyl dla Zwierząt',
    //     'address': 'ul. Schroniskowa 7, Kraków',
    //   },
    //   {
    //     'name': 'Fundacja "Szczęśliwy Ogon"',
    //     'address': 'ul. Kocia 22, Poznań',
    //   },
    //   {
    //     'name': 'Miejskie Schronisko dla Zwierząt',
    //     'address': 'ul. Pieskowa 10, Wrocław',
    //   },
    // ];
    //
    // final dogImages = [
    //   'https://images.pexels.com/photos/1805164/pexels-photo-1805164.jpeg',
    //   'https://images.pexels.com/photos/2253275/pexels-photo-2253275.jpeg',
    //   'https://images.pexels.com/photos/1346086/pexels-photo-1346086.jpeg',
    // ];
    //
    // final catImages = [
    //   'https://images.pexels.com/photos/45201/kitty-cat-kitten-pet-45201.jpeg',
    //   'https://images.pexels.com/photos/1056251/pexels-photo-1056251.jpeg',
    //   'https://images.pexels.com/photos/320014/pexels-photo-320014.jpeg',
    //   'https://images.pexels.com/photos/730896/pexels-photo-730896.jpeg',
    //   'https://images.pexels.com/photos/1543793/pexels-photo-1543793.jpeg',
    //   'https://images.pexels.com/photos/1170986/pexels-photo-1170986.jpeg',
    // ];
    //
    // List<PetModel> pets = [];
    //
    // // Pętla do losowego generowanie zwierząt do testów
    // for (int i = 0; i < petCount; i++) {
    //   final isPet = random.nextBool();
    //   final gender = random.nextBool() ? 'male' : 'female';
    //   final size = ['small', 'medium', 'large', 'xlarge'][random.nextInt(4)];
    //
    //   final shelter = shelters[random.nextInt(shelters.length)];
    //
    //   final breed = isPet ? dogBreeds[random.nextInt(dogBreeds.length)] : catBreeds[random.nextInt(catBreeds.length)];
    //   final imageList = isPet ? dogImages : catImages;
    //   final mainImage = imageList[random.nextInt(imageList.length)];
    //
    //   List<String> gallery = [];
    //   for (int j = 0; j < random.nextInt(4) + 2; j++) { // 2-5 zdjęć
    //     gallery.add(imageList[random.nextInt(imageList.length)]);
    //   }
    //
    //   pets.add(
    //     PetModel(
    //       id: 'pet_${DateTime.now().millisecondsSinceEpoch}_$i',
    //       name: names[random.nextInt(names.length)],
    //       age: random.nextInt(10) + 1, // 1-10 lat
    //       gender: gender,
    //       breed: breed,
    //       size: size,
    //       description: descriptions[random.nextInt(descriptions.length)],
    //       imageUrl: mainImage,
    //       galleryImages: gallery,
    //       distance: (random.nextInt(20) + 1) + random.nextDouble().round(), // 1-21 km
    //       isVaccinated: random.nextBool(),
    //       isNeutered: random.nextBool(),
    //       isChildFriendly: random.nextBool(),
    //       isUrgent: random.nextInt(10) < 3,
    //       shelterId: 'shelter_${DateTime.now().millisecondsSinceEpoch}_$i',
    //       shelterName: shelter['name']!,
    //       shelterAddress: shelter['address']!,
    //     ),
    //   );
    // }
    //
    // return pets;
    return _demoPets;
  }

  // Symulacja polubienia zwierzaka
  Future<void> likePet(String petId) async {
    /// TODO: Implementacja polubienia zwierzaka w bazie danych
    _likedPetIds.add(petId);
  }

  Future<void> unlikePet(String petId) async {
    /// TODO: Implementacja cofnięcia polubienia zwierzaka w bazie danych
    _likedPetIds.remove(petId);
  }

  // Zaktualizowana metoda w PetService
  Future<List<PetModel>> getLikedPets() async {
    /// TODO: Implementacja pobierania polubionych zwierząt z bazy danych
    return _demoPets.where((p) => _likedPetIds.contains(p.id)).toList();
    //
    // // TYMCZASOWA IMPLEMENTACJA:
    // final random = Random();
    // final petCount = random.nextInt(7) + 3;
    //
    // final pets = await getPets();
    //
    // pets.shuffle();
    // return pets.take(petCount).toList();
  }
}