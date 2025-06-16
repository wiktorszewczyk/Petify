const API_URL = "http://localhost:8222";
import { majorPolishCities } from '../assets/cities'; 

const mapTypeToEnum = {
  'Kot': 'CAT',
  'Pies': 'DOG',
  'Inny': 'OTHER'
};

export function getToken() {
  return localStorage.getItem("jwt");
}

export const fetchFavoritePets = async () => {
  const token = getToken();

  const response = await fetch(`${API_URL}/pets/favorites`, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (response.status === 404) {
    return [];
  }

  if (!response.ok) {
    throw new Error("Wystąpił błąd serwera.");
  }

  return await response.json();
};

export const fetchShelters = async () => {
  const token = getToken();

  const response = await fetch(`${API_URL}/shelters`, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (response.status === 404) {
    return []; 
  }

  if (!response.ok) {
    throw new Error("Błąd podczas pobierania schronisk");
  }

  const data = await response.json();
  return Array.isArray(data.content) ? data.content : [];
};

export const fetchShelterById = async (shelterId) => {
  const token = getToken();

  const response = await fetch(`${API_URL}/shelters/${shelterId}`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error("Nie udało się pobrać danych schroniska");
  }

  return await response.json();
};



export const fetchImagesByPetId = async (petId) => {
  const token = getToken();
  const response = await fetch(`${API_URL}/pets/${petId}/images`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) return [];
  return await response.json();
};


export const fetchPetById = async (petId) => {
  const token = getToken();
  const response = await fetch(`${API_URL}/pets/${petId}`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error("Nie udało się pobrać danych zwierzaka.");
  }

  return await response.json();
};

export const fetchShelterProfileById = async (shelterId) => {
  const token = getToken();
  const response = await fetch(`${API_URL}/shelters/${shelterId}`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error("Nie udało się pobrać danych schroniska.");
  }

  return await response.json();
};

export const fetchFilteredAnimals = async (filters, cursor = 1) => {
  const jwt = getToken();
  const params = new URLSearchParams();

 if (filters.type && filters.type !== 'Wszystkie') {
  const mappedType = mapTypeToEnum[filters.type];
  if (mappedType) {
    params.append("type", mappedType);
  }
}
  params.append("minAge", filters.ageRange[0]);
params.append("maxAge", filters.ageRange[1]);
  if (filters.vaccinated) params.append("vaccinated", filters.vaccinated);
  if (filters.urgent) params.append("urgent", filters.urgent);
 if (filters.city) {
    const found = majorPolishCities.find(c => c.name === filters.city);
    if (found) {
      params.append("userLat", found.lat);
      params.append("userLng", found.lon);
    }
  }

  if (filters.distance) {
    params.append("radiusKm", filters.distance);
  }
  params.append("limit", 10);
  params.append("cursor", cursor);


  const response = await fetch(`${API_URL}/pets/filter?${params.toString()}`, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${jwt}`,
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    throw new Error("Błąd pobierania danych");
  }

  const data = await response.json();
  const pets = Array.isArray(data.pets) ? data.pets : [];
  const enrichedAnimals = await Promise.all(
    pets.map(async (animal) => {
      let shelterName = `Schronisko #${animal.shelterId}`;
      let shelterAddress = '';

      try {
        const shelterRes = await fetch(`${API_URL}/shelters/${animal.shelterId}`, {
          headers: {
            Authorization: `Bearer ${jwt}`,
          },
        });

        if (shelterRes.ok) {
          const shelter = await shelterRes.json();
          shelterName = shelter.name;
          shelterAddress = shelter.address || '';
        }
      } catch (e) {
        console.warn(`Nie udało się pobrać danych schroniska dla ID ${animal.shelterId}`);
      }

      return {
        ...animal,
        photos: animal.images?.map((img) => img.imageUrl) || [],
        shelterAddress,
        shelterName,
      };
    })
  );

  return enrichedAnimals;
};

export const likePet = async (petId) => {
  const jwt = getToken();

  const response = await fetch(`${API_URL}/pets/${petId}/like`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${jwt}`,
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    throw new Error("Nie udało się polubić zwierzaka");
  }
};