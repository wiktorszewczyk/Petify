const API_URL = "http://localhost:9000";

export const fetchFavoritePets = async () => {
  const token = localStorage.getItem("jwt");

  const response = await fetch(`${API_URL}/pets/favorites`, {
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
  const token = localStorage.getItem("jwt");

  const response = await fetch(`${API_URL}/shelters`, {
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