
const API_URL = "http://localhost:9000";

export async function login(loginIdentifier, password) {
  const response = await fetch(`${API_URL}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ loginIdentifier, password }),
  });

  let data;
  try {
    data = await response.json();
  } catch (err) {
    // ❌ brak JSON = prawdopodobnie konto nie istnieje
    throw new Error("Nie znaleziono konta.");
  }

  if (response.ok) {
    if (data?.jwt) {
      localStorage.setItem("jwt", data.jwt);
      return data;
    } else {
      throw new Error("Brak tokenu w odpowiedzi.");
    }
  } else {
    // ❗ JSON istnieje, ale to nie 2xx – więc coś poszło źle
    // zakładamy, że konto istnieje, ale np. hasło złe
    if (response.status === 401 || response.status === 403) {
      throw new Error("Nieprawidłowe hasło.");
    }

    // fallback na inne błędy
    throw new Error("Logowanie nieudane.");
  }
}

export async function uploadProfileImage(file) {
  const token = getToken();
  const formData = new FormData();
  formData.append("image", file);

  const response = await fetch(`${API_URL}/user/profile-image`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
    },
    body: formData,
  });

  if (!response.ok) {
    throw new Error("Błąd podczas wysyłania zdjęcia");
  }

  return await response.json();
}



export async function register(userData) {
  const response = await fetch(`${API_URL}/auth/register`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      username: userData.email,
      password: userData.password,
      firstName: userData.firstName,
      lastName: userData.lastName,
      birthDate: userData.birthDate,
      gender: userData.gender,
      phoneNumber: userData.phoneNumber,
      email: userData.email
    }),
  });

  const data = await response.json();

  if (response.ok) {
    return data;
  } else {
    throw new Error(data.error || "Rejestracja nieudana");
  }
}

export async function fetchUserData() {
  const token = getToken();

  const response = await fetch(`${API_URL}/user`, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error("Nie udało się pobrać danych użytkownika");
  }

  const user = await response.json();

  return {
    firstName: user.firstName,
    lastName: user.lastName,
    birthDate: user.birthDate,
    gender: user.gender,
    phoneNumber: user.phoneNumber,
    email: user.email,
    city: user.city,
    volunteerStatus: user.volunteerStatus,

    level: user.level,
    xpPoints: user.xpPoints,
    xpToNextLevel: user.xpToNextLevel,
    likesCount: user.likesCount,
    supportCount: user.supportCount,
    badgesCount: user.badgesCount,

    achievements: user.achievements || [],

    profileImageBase64: user.profileImage,
  };
}

export function getToken() {
  return localStorage.getItem("jwt");
}

export function isAuthenticated() {
  const token = localStorage.getItem("jwt");
  return !!token;
}

export async function handleGoogleLogin(idToken) {
  const res = await fetch(`${API_URL}/auth/oauth2/exchange`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      provider: "google",
      access_token: idToken
    })
  });

  const data = await res.json();

  if (res.ok && data?.jwt) {
    localStorage.setItem("jwt", data.jwt);
    return data;
  } else {
    throw new Error(data?.error || "Błąd logowania przez Google");
  }
}

export function logout() {
  localStorage.removeItem("jwt");
  window.location.href = "/login"; // przekierowanie do strony logowania
}

export const updateUserData = async (data) => {
  const response = await fetch(`${API_URL}/user`, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${getToken()}`,
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    throw new Error("Błąd podczas aktualizacji danych użytkownika");
  }

  return await response.json();
};

export async function fetchProfileImage() {
  const token = getToken();

  const response = await fetch(`${API_URL}/user/profile-image`, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });

  if (!response.ok) {
    throw new Error("Nie udało się pobrać zdjęcia profilowego");
  }

  const blob = await response.blob();
  return URL.createObjectURL(blob);
}
