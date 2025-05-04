import 'dart:math';
import 'dart:async';
import '../models/shelter_model.dart';

class ShelterService {
  static final ShelterService _instance = ShelterService._internal();

  factory ShelterService() {
    return _instance;
  }

  ShelterService._internal();

  // Pobieranie listy schronisk (symulacja API)
  /// TODO: Implementacja API do pobierania schronisk
  Future<List<ShelterModel>> getShelters() async {
    final random = Random();

    final shelterCount = random.nextInt(4) + 6; // 6-10 schronisk

    final shelterNames = [
      'Schronisko "Pod Dobrą Łapą"',
      'Azyl dla Zwierząt',
      'Fundacja "Szczęśliwy Ogon"',
      'Miejskie Schronisko dla Zwierząt',
      'Fundacja "Łapa w Łapę"',
      'Przytulisko "Zwierzęcy Dom"',
      'Schronisko "Psia Przystań"',
      'Kocia Przystań',
      'Schronisko "Reksio"',
      'Fundacja Pomocy Zwierzętom "Bezdomniaki"',
      'Stowarzyszenie Opieki nad Zwierzętami "Nadzieja"',
      'Fundacja "Cztery Łapy"'
    ];

    final cities = [
      'Warszawa', 'Kraków', 'Poznań', 'Wrocław', 'Gdańsk',
      'Łódź', 'Szczecin', 'Bydgoszcz', 'Lublin', 'Katowice'
    ];

    final streets = [
      'Adopcyjna', 'Schroniskowa', 'Kocia', 'Pieskowa', 'Zwierzęca',
      'Opiekuńcza', 'Przyjaciół Zwierząt', 'Dobrej Woli', 'Azylu', 'Pomocna'
    ];

    final descriptions = [
      'Nasze schronisko zajmuje się opieką nad bezdomnymi zwierzętami od ponad 15 lat. Zapewniamy naszym podopiecznym profesjonalną opiekę weterynaryjną, ciepłe schronienie i codzienną porcję miłości.',
      'Pomagamy zwierzętom w potrzebie, zapewniając im bezpieczne schronienie i poszukując dla nich nowych, kochających domów. Prowadzimy również programy edukacyjne dla społeczności lokalnej.',
      'Fundacja powstała z miłości do czworonogów. Naszym celem jest pomoc bezdomnym i porzuconym zwierzętom oraz walka o poprawę ich losu. Warunki w naszym schronisku staramy się uczynić jak najbardziej przyjazne dla zwierząt.',
      'Miejskie schronisko z wieloletnią tradycją. Zapewniamy opiekę psom i kotom, które straciły dom. Prowadzimy również programy adopcyjne i współpracujemy z wolontariuszami.',
      'Jesteśmy małym, ale prężnie działającym schroniskiem. Naszym celem jest znalezienie nowych domów dla wszystkich naszych podopiecznych. Oferujemy również usługi weterynaryjne dla zwierząt z ubogich rodzin.',
      'Nasza fundacja koncentruje się na ratowaniu zwierząt z trudnych warunków. Prowadzimy również programy edukacyjne i współpracujemy z lokalnymi szkołami.',
    ];

    final needs = [
      'Karma sucha i mokra dla psów i kotów',
      'Koce, poduszki i legowiska',
      'Środki czystości',
      'Zabawki dla zwierząt',
      'Smycze i obroże',
      'Leki i środki medyczne',
      'Kuwety i żwirek dla kotów',
      'Wsparcie finansowe na leczenie weterynaryjne',
      'Materiały budowlane do naprawy boksów',
      'Pomoc wolontariuszy przy wyprowadzaniu psów'
    ];

    final images = [
      'https://images.pexels.com/photos/1634840/pexels-photo-1634840.jpeg',
      'https://images.pexels.com/photos/1350588/pexels-photo-1350588.jpeg',
      'https://images.pexels.com/photos/2607544/pexels-photo-2607544.jpeg',
      'https://images.pexels.com/photos/1633522/pexels-photo-1633522.jpeg',
      'https://images.pexels.com/photos/1906153/pexels-photo-1906153.jpeg',
      'https://images.pexels.com/photos/551628/pexels-photo-551628.jpeg',
      'https://images.pexels.com/photos/406014/pexels-photo-406014.jpeg',
    ];

    List<ShelterModel> shelters = [];

    List<String> usedNames = [];

    // Generowanie losowych schronisk do testów
    for (int i = 0; i < shelterCount; i++) {
      String shelterName;
      do {
        shelterName = shelterNames[random.nextInt(shelterNames.length)];
      } while (usedNames.contains(shelterName));
      usedNames.add(shelterName);

      final city = cities[random.nextInt(cities.length)];
      final street = streets[random.nextInt(streets.length)];
      final streetNumber = random.nextInt(50) + 1;
      final address = 'ul. $street $streetNumber, $city';
      final description = descriptions[random.nextInt(descriptions.length)];
      final imageUrl = images[random.nextInt(images.length)];

      final shelterNeeds = <String>[];
      final needsCount = random.nextInt(4) + 2;
      final allNeeds = List<String>.from(needs);
      allNeeds.shuffle();
      shelterNeeds.addAll(allNeeds.take(needsCount));

      final petsCount = random.nextInt(100) + 50;

      final volunteersCount = random.nextInt(30) + 5;

      final isUrgent = random.nextInt(10) < 3; // 30% szans

      shelters.add(
        ShelterModel(
          id: 'shelter_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: shelterName,
          address: address,
          description: description,
          imageUrl: imageUrl,
          petsCount: petsCount,
          volunteersCount: volunteersCount,
          needs: shelterNeeds,
          phoneNumber: '+48 ${random.nextInt(900) + 100} ${random.nextInt(900) + 100} ${random.nextInt(900) + 100}',
          email: shelterName.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '') + '@schronisko.pl',
          website: 'www.${shelterName.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}.pl',
          isUrgent: isUrgent,
          donationGoal: (random.nextInt(10) + 5) * 1000, // 5000-15000 PLN
          donationCurrent: (random.nextInt(5)) * 1000, // 0-5000 PLN
          city: city,
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 800));

    return shelters;
  }

  // Symulacja wsparcia schroniska
  Future<bool> donateShelter(String shelterId, double amount) async {
    /// TODO: Implementacja wsparcia schroniska w bazie danych
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}