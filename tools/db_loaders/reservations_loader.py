from datetime import datetime, timedelta
import json
import os
import random

import requests

BASE_URL = os.getenv("BASE_URL", "http://localhost:8222")


with open("test_data/data/shelter_users.json", "r", encoding="UTF-8") as f:
    users = json.load(f)
with open("test_data/data/volunteers.json", "r", encoding="UTF-8") as f:
    volunteers = json.load(f)

response = requests.post(
    f"{BASE_URL}/auth/login",
    json={"loginIdentifier": users[0]["email"], "password": users[0]["password"]},
    timeout=5,
)
shelter_headers = {
    "Authorization": f"Bearer {response.json()['jwt']}",
}
response = requests.get(
    f"{BASE_URL}/shelters/1/pets?size=100", headers=shelter_headers, timeout=5
)

for idx, pet in enumerate(response.json()["content"]):
    if pet["type"] != "DOG":
        continue

    start_date = datetime(2025, 6, 22)
    end_date = datetime(2025, 6, 30)
    delta = timedelta(days=1)
    slot_duration = timedelta(minutes=30)
    slot_start_times = [10, 14, 18]

    slots_per_day = 2 if idx % 2 == 0 else 3

    current_date = start_date
    while current_date <= end_date:
        for slot_num in range(slots_per_day):
            hour = slot_start_times[slot_num]
            slot_start = current_date.replace(
                hour=hour, minute=0, second=0, microsecond=0
            )
            slot_end = slot_start + slot_duration
            payload = {
                "petId": pet["id"],
                "startTime": slot_start.isoformat(),
                "endTime": slot_end.isoformat(),
            }
            response = requests.post(
                f"{BASE_URL}/reservations/slots",
                json=payload,
                headers=shelter_headers,
                timeout=5,
            )
            print(
                f"Created reservation slot for Pet ID: {pet['id']} - Status: {response.status_code}"
            )

            if response.status_code == 201 and random.random() < 0.2:
                slot_id = response.json()["id"]
                volunteer = random.choice(volunteers)
                volunteer_login = requests.post(
                    f"{BASE_URL}/auth/login",
                    json={
                        "loginIdentifier": volunteer["email"],
                        "password": volunteer["password"],
                    },
                    timeout=5,
                )
                volunteer_headers = {
                    "Authorization": f"Bearer {volunteer_login.json()['jwt']}",
                }
                reserve_response = requests.patch(
                    f"{BASE_URL}/reservations/slots/{slot_id}/reserve",
                    headers=volunteer_headers,
                    timeout=5,
                )
                print(
                    f"Reserved slot {slot_id} by volunteer {volunteer['email']} - Status: {reserve_response.status_code}"
                )
        current_date += delta
