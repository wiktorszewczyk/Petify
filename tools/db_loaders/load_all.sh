# Fill out and uncomment
export JWT_ADMIN="<your_jwt_admin_token>"
export BASE_URL="http://localhost:8222"

python3 tools/db_loaders/shelter_loader.py
python3 tools/db_loaders/pet_loader.py
python3 tools/db_loaders/volunteer_loader.py
python3 tools/db_loaders/funding_loader.py
python3 tools/db_loaders/feed_loader.py
python3 tools/db_loaders/reservations_loader.py
