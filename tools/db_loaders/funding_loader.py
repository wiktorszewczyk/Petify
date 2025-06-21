import json
import os

import requests

BASE_URL = os.getenv("BASE_URL", "http://localhost:8222")

with open("data/fundings.json", "r", encoding="UTF-8") as f:
    fundings = json.load(f)

with open("data/shelter_users.json", "r", encoding="UTF-8") as f:
    users = json.load(f)

for funding in fundings:
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={
            "loginIdentifier": users[funding["shelterId"] - 1]["email"],
            "password": users[funding["shelterId"] - 1]["password"],
        },
        timeout=5,
    )
    print(
        f"Logged in user: {users[funding['shelterId'] - 1]['email']} - Status: {response.status_code}"
    )

    headers = {"Authorization": f"Bearer {response.json()['jwt']}"}
    response = requests.post(
        f"{BASE_URL}/fundraisers", headers=headers, json=funding, timeout=5
    )
    if response.status_code == 201:
        print(f"Funding created successfully: {funding['title']}")
    else:
        print(
            f"Failed to create funding: {funding['title']} - Status Code: {response.status_code}, Error: {response.text}"
        )
