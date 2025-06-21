import json
import os

import mimetypes
import requests

BASE_URL = os.getenv("BASE_URL", "http://localhost:8222")


with open("test_data/data/shelter_users.json", "r", encoding="UTF-8") as f:
    users = json.load(f)
with open("test_data/data/shelters.json", "r", encoding="UTF-8") as f:
    shelters = json.load(f)

for user, shelter in zip(users, shelters):
    # Register user
    response = requests.post(f"{BASE_URL}/auth/register", json=user, timeout=5)
    print(f"Registered user: {user['email']} - Status: {response.status_code}")

    # Login user
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={
            "loginIdentifier": user["email"],
            "password": user["password"],
        },
        timeout=5,
    )
    print(f"Logged in user: {user['email']} - Status: {response.status_code}")

    # Upload image
    headers = {"Authorization": f"Bearer {response.json()['jwt']}"}
    response = requests.post(
        f"{BASE_URL}/user/profile-image",
        headers=headers,
        files={
            "image": (
                os.path.basename(shelter["imagePath"]),
                open(shelter["imagePath"], "rb"),
                mimetypes.guess_type(shelter["imagePath"])[0]
                or "application/octet-stream",
            )
        },
        timeout=5,
    )
    print(f"Uploaded image for user: {user['email']} - Status: {response.status_code}")

    # Create shelter
    response = requests.post(
        f"{BASE_URL}/shelters",
        headers=headers,
        files={
            "shelterRequest": (None, json.dumps(shelter), "application/json"),
            "imageFile": (
                os.path.basename(shelter["imagePath"]),
                open(shelter["imagePath"], "rb"),
                mimetypes.guess_type(shelter["imagePath"])[0]
                or "application/octet-stream",
            ),
        },
        timeout=5,
    )
    print(f"Created shelter for user: {user['email']} - Status: {response.status_code}")

    # Activate shelter
    shelter_id = response.json()["id"]
    headers = {"Authorization": f"Bearer {os.getenv('JWT_ADMIN')}"}
    response = requests.post(
        f"{BASE_URL}/shelters/{shelter_id}/activate", headers=headers, timeout=5
    )
    print(
        f"Activated shelter for user: {user['email']} - Status: {response.status_code}"
    )
