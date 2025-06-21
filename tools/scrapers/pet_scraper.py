#!/usr/bin/env python3
import hashlib
import json
import os
import random
import re
import time
import uuid
from pathlib import Path
from urllib.parse import parse_qs, urljoin, urlparse

import requests
from bs4 import BeautifulSoup

# -----------------------------------------------------------------------------
# Konfiguracja aplikacji
# -----------------------------------------------------------------------------

BASE_URL: str = "https://schronisko-lodz.pl/index.php?p=adopcje_v2"
OUTPUT_DIR: Path = Path("test_data/images/pets")
JSON_OUT: Path = Path("test_data/data/pets.json")

KEYWORDS = {
    "age": ("wiek",),
    "size": ("wielko", "wielko�"),
    "gender": ("płe", "p�e", "plec"),
}

session = requests.Session()
session.headers.update(
    {
        "User-Agent": "Mozilla/5.0 (compatible; AdoptScraper/1.1; +https://example.com)",
    }
)

# -----------------------------------------------------------------------------
# Normalizacja pól
# -----------------------------------------------------------------------------


def normalize_gender(text: str) -> tuple[str | None, str | None]:
    t = text.lower()
    if "kocur" in t:
        return "CAT", "MALE"
    if "kotka" in t:
        return "CAT", "FEMALE"
    if "pies" in t and "suk" not in t:
        return "DOG", "MALE"
    if "suka" in t:
        return "DOG", "FEMALE"
    return None, None


def normalize_size(text: str) -> str | None:
    t = text.lower()
    if "bardzo" in t:
        return "VERY_BIG"
    if "duż" in t or "du�" in t:
        return "BIG"
    if "śre" in t or "sre" in t or "�red" in t:
        return "MEDIUM"
    if "mał" in t or "ma�" in t:
        return "SMALL"
    return None


def parse_age(text: str) -> int | None:
    m = re.search(r"\d+", text)
    return int(m.group()) if m else None


# -----------------------------------------------------------------------------
# Funkcje pomocnicze HTTP/HTML
# -----------------------------------------------------------------------------


def get_soup(url: str, **kwargs) -> BeautifulSoup:
    resp = session.get(url, timeout=30, **kwargs)
    resp.encoding = resp.apparent_encoding
    return BeautifulSoup(resp.text, "html.parser")


def is_detail_link(tag) -> bool:
    if tag.name != "a" or not tag.has_attr("href"):
        return False
    qs = parse_qs(urlparse(urljoin(BASE_URL, tag["href"])).query)
    return qs.get("a", [None])[0] == "view_details"


# -----------------------------------------------------------------------------
# Operacje na plikach / obrazach
# -----------------------------------------------------------------------------


def ensure_dir(p: Path) -> None:
    p.mkdir(parents=True, exist_ok=True)


def download_unique_image(
    url: str, dest_dir: Path, stem: str, known_hashes: set[str]
) -> Path | None:
    r = session.get(url, timeout=30)
    r.raise_for_status()
    data = r.content
    h = hashlib.sha256(data).hexdigest()
    if h in known_hashes:
        return None

    ext = os.path.splitext(urlparse(url).path)[1] or ".jpg"
    dest = dest_dir / f"{stem}{ext}"
    ensure_dir(dest.parent)
    with open(dest, "wb") as fh:
        fh.write(data)

    known_hashes.add(h)
    return dest


def random_bool(prob_true: float) -> bool:
    return random.random() < prob_true


# -----------------------------------------------------------------------------
# Ekstrakcja wartości z HTML
# -----------------------------------------------------------------------------


def row_value(soup: BeautifulSoup, keys: tuple[str, ...]) -> str | None:
    """Zwraca zawartość <strong> z drugiej kolumny pasującego wiersza."""
    for k in keys:
        hdr = soup.find(string=lambda t: t and k in t.lower())
        if hdr:
            left = hdr.find_parent("div")
            right = left.find_next_sibling("div") if left else None
            if right and right.strong:
                return right.strong.get_text(strip=True)
    return None


# -----------------------------------------------------------------------------
# Parser podstrony ze zwierzakiem
# -----------------------------------------------------------------------------


def parse_details(url: str) -> dict | None:
    soup = get_soup(url)

    # Imię
    name_tag = soup.select_one("h2 > strong")
    if not name_tag:
        return None
    name = name_tag.get_text(strip=True)

    # Metryka (płeć, wielkość, wiek)
    gender_raw = row_value(soup, KEYWORDS["gender"])
    size_raw = row_value(soup, KEYWORDS["size"])
    age_raw = row_value(soup, KEYWORDS["age"])

    if not (gender_raw and size_raw and age_raw):
        # fallback – skanuj wszystkie <strong>
        for s in soup.find_all("strong"):
            txt = s.get_text(strip=True)
            if not gender_raw and normalize_gender(txt)[0]:
                gender_raw = txt
            if not size_raw and normalize_size(txt):
                size_raw = txt
            if not age_raw and re.match(r"\d+$", txt):
                age_raw = txt

    pet_type, gender = normalize_gender(gender_raw or "")
    size = normalize_size(size_raw or "")
    age = parse_age(age_raw or "")

    if not all([pet_type, gender, size, age is not None]):
        return None

    # Opis
    desc_tag = soup.select_one(".card-body")
    description = desc_tag.get_text(" ", strip=True) if desc_tag else ""

    # Zdjęcia
    main_img_tag = soup.select_one("div.col-md-5 img, div.col-lg-5 img")
    if not main_img_tag or not main_img_tag.get("src"):
        return None
    main_img_url = urljoin(url, main_img_tag["src"])

    gallery_urls = [
        urljoin(url, a["href"])
        for a in soup.select('a[data-lightbox="default-gallery"][href]')
    ]
    random.shuffle(gallery_urls)
    gallery_urls = gallery_urls[:4]

    # Katalog zwierzaka
    pet_hash = uuid.uuid4().hex
    pet_dir = OUTPUT_DIR / pet_hash
    ensure_dir(pet_dir)

    # --- Pobieramy obrazy z eliminacją duplikatów --------------------------
    hashes: set[str] = set()

    main_path = download_unique_image(main_img_url, pet_dir, "main", hashes)
    if main_path is None:
        return None

    image_paths: list[str] = []
    for idx, img_url in enumerate(gallery_urls, start=1):
        p = download_unique_image(img_url, pet_dir, str(idx), hashes)
        if p:
            image_paths.append(str(p))

    # ----------------------------------------------------------------------
    return {
        "name": name,
        "type": pet_type,
        "breed": None,
        "age": age,
        "description": description,
        "gender": gender,
        "size": size,
        "vaccinated": random_bool(0.8),
        "urgent": random_bool(0.3),
        "sterilized": random_bool(0.8),
        "kidFriendly": random_bool(0.8),
        "mainImagePath": str(main_path),
        "imagePaths": image_paths,
    }


# -----------------------------------------------------------------------------
# Pętla główna – iteracja po stronach listy
# -----------------------------------------------------------------------------


def scrape(max_pages: int | None = None) -> None:
    ensure_dir(OUTPUT_DIR)
    results: list[dict] = []

    page = 1
    while True:
        list_url = f"{BASE_URL}&page={page}"
        soup = get_soup(list_url)

        raw_links = [
            urljoin(BASE_URL, a["href"]) for a in soup.find_all(is_detail_link)
        ]
        links = list(dict.fromkeys(raw_links))
        if not links:
            break

        print(f"Strona {page} – {len(links)} linków")
        for link in links:
            try:
                pet = parse_details(link)
                if pet:
                    results.append(pet)
                    print(" ✔", end="", flush=True)
                else:
                    print(" ✖", end="", flush=True)
            except Exception as e:
                print(f"\nBłąd przy {link}: {e}")
            time.sleep(random.uniform(0.3, 0.7))
        print()

        page += 1
        if max_pages and page > max_pages:
            break
        time.sleep(random.uniform(1.0, 2.0))

    ensure_dir(JSON_OUT.parent)
    with open(JSON_OUT, "w", encoding="utf-8") as fh:
        json.dump(results, fh, ensure_ascii=False, indent=2)

    print(f"\nZapisano {len(results)} rekordów do {JSON_OUT}")


# -----------------------------------------------------------------------------
if __name__ == "__main__":
    scrape(max_pages=8)
