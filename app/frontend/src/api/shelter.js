const API_URL = "";

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

  return await response.json();
};

export const fetchShelterById = async (shelterId) => {
  const token = getToken();

  const response = await fetch(`/shelters/${shelterId}`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error("Nie udało się pobrać danych schroniska");
  }

  return await response.json();
};