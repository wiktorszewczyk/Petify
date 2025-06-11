
const API_URL = "http://localhost:9000";

export async function login(loginIdentifier, password) {
  const response = await fetch(`${API_URL}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ loginIdentifier, password }),
  });

  const data = await response.json();
  if (response.ok) {
    localStorage.setItem("jwt", data.jwt); // zamiast data.token
    return data;
  } else {
    throw new Error(data.error || "Logowanie nieudane");
  }
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

  const [achievementsRes, levelRes] = await Promise.all([
    fetch(`${API_URL}/user/achievements/`, {
      headers: { Authorization: `Bearer ${token}` }
    }),
    fetch(`${API_URL}/user/achievements/level`, {
      headers: { Authorization: `Bearer ${token}` }
    }),
  ]);

  const achievements = await achievementsRes.json();
  const level = await levelRes.json();

  // 🔧 Połącz dane w jedną strukturę pod twoje potrzeby
  return {
    firstName: level.firstName ?? "Jan", // jeśli nie ma, dodaj fallback
    lastName: level.lastName ?? "Kowalski",
    level: level.level,
    xpPoints: level.xpPoints,
    xpToNextLevel: level.xpToNextLevel,
    likesCount: level.likesCount,
    supportCount: level.supportCount,
    badgesCount: level.badgesCount,
    achievements: achievements
  };
}

export function getToken() {
  return localStorage.getItem("jwt");
}

export function isAuthenticated() {
  const token = localStorage.getItem("jwt");
  return !!token;
}

async function handleGoogleLogin(idToken) {
  const res = await fetch(`${API_URL}/auth/oauth2-login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ token: idToken })
  });

  const data = await res.json();
  if (res.ok) {
    localStorage.setItem("jwt", data.jwt); // lub inne dane
  } else {
    alert("Błąd logowania przez Google");
  }
}