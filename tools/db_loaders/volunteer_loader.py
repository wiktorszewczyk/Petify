import json
import os

import requests

BASE_URL = os.getenv("BASE_URL", "http://localhost:8222")


with open("test_data/data/volunteers.json", "r", encoding='UTF-8') as f:
    volunteers = json.load(f)

application_id = 1
for volunteer in volunteers:
    # Register volunteer
    response = requests.post(f"{BASE_URL}/auth/register", json=volunteer, timeout=5)
    print(
        f"Registered volunteer: {volunteer['email']} - Status: {response.status_code}"
    )

    # Login volunteer
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={"loginIdentifier": volunteer["email"], "password": volunteer["password"]},
        timeout=5,
    )
    print(f"Logged in volunteer: {volunteer['email']} - Status: {response.status_code}")

    # Apply to be a volunteer
    headers = {"Authorization": f"Bearer {response.json()['jwt']}"}
    user_id = response.json()["user"]["userId"]
    response = requests.post(
        f"{BASE_URL}/volunteer/apply", headers=headers, json={}, timeout=5
    )
    print(
        f"Applied to be a volunteer: {volunteer['email']} - Status: {response.status_code}"
    )

    # Approve volunteer
    headers = {"Authorization": f"Bearer {os.getenv('JWT_ADMIN')}"}
    response = requests.put(
        f"{BASE_URL}/volunteer/applications/{application_id}/approve",
        headers=headers,
        json={},
        timeout=5,
    )
    print(f"Approved volunteer: {volunteer['email']} - Status: {response.status_code}")
    application_id += 1
