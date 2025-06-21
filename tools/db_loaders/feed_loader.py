import json
import os

import mimetypes
import requests

BASE_URL = os.getenv("BASE_URL", "http://localhost:8222")


with open("test_data/data/images.json", "r", encoding="UTF-8") as f:
    images = json.load(f)
with open("test_data/data/events.json", "r", encoding="UTF-8") as f:
    events = json.load(f)
with open("test_data/data/posts.json", "r", encoding="UTF-8") as f:
    posts = json.load(f)
with open("test_data/data/shelter_users.json", "r", encoding="UTF-8") as f:
    users = json.load(f)

# Events
for image_id, event in enumerate(events):
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={
            "loginIdentifier": users[event["shelterId"] - 1]["email"],
            "password": users[event["shelterId"] - 1]["password"],
        },
        timeout=5,
    )
    print(
        f"Logged in user: {users[event['shelterId'] - 1]['email']} - Status: {response.status_code}"
    )

    # Create event
    headers = {
        "Authorization": f"Bearer {response.json()['jwt']}",
    }
    response = requests.post(
        f"{BASE_URL}/events/shelter/{event["shelterId"]}/events",
        headers=headers,
        json=event,
        timeout=5,
    )
    print(f"Created event: {event['title']} - Status: {response.status_code}")

    # Upload related image
    event_id = response.json().get("id")
    response = requests.post(
        f"{BASE_URL}/images/feed/{event_id}/images",
        headers=headers,
        files={
            "images": (
                os.path.basename(images[image_id]["imagePath"]),
                open(images[image_id]["imagePath"], "rb"),
                mimetypes.guess_type(images[image_id]["imagePath"])[0]
                or "application/octet-stream",
            )
        },
        timeout=5,
    )
    print(
        f"Uploaded image for event: {event['title']} - Status: {response.status_code}"
    )


# Posts
for post in posts:
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={
            "loginIdentifier": users[0]["email"],
            "password": users[0]["password"],
        },
        timeout=5,
    )
    print(f"Logged in user: {users[0]['email']} - Status: {response.status_code}")

    # Create post
    headers = {
        "Authorization": f"Bearer {response.json()['jwt']}",
    }
    response = requests.post(
        f"{BASE_URL}/posts/shelter/1/posts",
        headers=headers,
        json=post,
        timeout=5,
    )
    print(f"Created post: {post['title']} - Status: {response.status_code}")

    # Upload related images
    post_id = response.json()["id"]
    local_image_ids = post["localImageIds"]
    files = []
    for image_id in local_image_ids:
        files.append(
            (
                "images",
                (
                    os.path.basename(images[image_id]["imagePath"]),
                    open(images[image_id]["imagePath"], "rb"),
                    mimetypes.guess_type(images[image_id]["imagePath"])[0]
                    or "application/octet-stream",
                ),
            )
        )
    response = requests.post(
        f"{BASE_URL}/images/feed/{post_id}/images",
        headers=headers,
        files=files,
        timeout=5,
    )
    print(f"Uploaded image for post: {post['title']} - Status: {response.status_code}")
