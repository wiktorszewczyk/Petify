import json
import os

import mimetypes
import requests

BASE_URL = os.getenv("BASE_URL", "http://localhost:8222")


with open("test_data/data/shelter_users.json", "r", encoding="UTF-8") as f:
    users = json.load(f)
with open("test_data/data/pets.json", "r", encoding="UTF-8") as f:
    pets = json.load(f)
with open("test_data/data/unique_pets.json", "r", encoding="UTF-8") as f:
    unique_pets = json.load(f)

pet_counts = [len(pets) - 135, 65, 40, 30]

pet_index = 0
for user_id, user in enumerate(users):
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={"loginIdentifier": user["email"], "password": user["password"]},
        timeout=5,
    )
    print(f"Logged in user: {user['email']} - Status: {response.status_code}")

    headers = {"Authorization": f"Bearer {response.json()['jwt']}"}

    for _ in range(pet_counts[user_id]):
        pet = pets[pet_index]
        pet_index += 1

        response = requests.post(
            f"{BASE_URL}/pets",
            headers=headers,
            files={
                "petRequest": (None, json.dumps(pet), "application/json"),
                "imageFile": (
                    os.path.basename(pet["mainImagePath"]),
                    open(pet["mainImagePath"], "rb"),
                    mimetypes.guess_type(pet["mainImagePath"])[0]
                    or "application/octet-stream",
                ),
            },
            timeout=5,
        )
        pet_id = response.json().get("id")
        print(f"Created pet for user: {user['email']} - Status: {response.status_code}")
        if pet["imagePaths"]:
            files = []
            for image_path in pet["imagePaths"]:
                files.append(
                    (
                        "images",
                        (
                            os.path.basename(image_path),
                            open(image_path, "rb"),
                            mimetypes.guess_type(image_path)[0]
                            or "application/octet-stream",
                        ),
                    )
                )
            response = requests.post(
                f"{BASE_URL}/pets/{pet_id}/images",
                headers=headers,
                files=files,
                timeout=5,
            )
            print(f"Uploaded images for pet: {pet_id} - Status: {response.status_code}")

for unique_pet in unique_pets:
    response = requests.post(
        f"{BASE_URL}/pets",
        headers=headers,
        files={
            "petRequest": (None, json.dumps(unique_pet), "application/json"),
            "imageFile": (
                os.path.basename(unique_pet["mainImagePath"]),
                open(unique_pet["mainImagePath"], "rb"),
                mimetypes.guess_type(unique_pet["mainImagePath"])[0]
                or "application/octet-stream",
            ),
        },
        timeout=5,
    )
    pet_id = response.json().get("id")
    print(f"Created unique pet - Status: {response.status_code}")
    if unique_pet.get("imagePaths"):
        imagePaths = unique_pet["imagePaths"]
        files = []
        for image_path in imagePaths:
            files.append(
                (
                    "images",
                    (
                        os.path.basename(image_path),
                        open(image_path, "rb"),
                        mimetypes.guess_type(image_path)[0]
                        or "application/octet-stream",
                    ),
                )
            )
        response = requests.post(
            f"{BASE_URL}/pets/{pet_id}/images", headers=headers, files=files, timeout=5
        )
        print(
            f"Uploaded images for unique pet: {pet_id} - Status: {response.status_code}"
        )
