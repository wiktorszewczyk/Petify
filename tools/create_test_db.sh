# export JWT_ADMIN="<your_jwt_admin_token>"
# export BASE_URL="http://localhost:8222"
# export PGUSER="your_postgres_user"
# export PGPASSWORD="your_postgres_password"

python3 tools/scrapers/pet_scraper.py
. tools/db_loaders/load_all.sh  # update JWT_ADMIN and optionally BASE_URL
docker run --rm --network=host -e PGUSER=$PGUSER -e PGPASSWORD=$PGPASSWORD postgres:17 pg_dump -h localhost -d petify > test_data/backup.sql
