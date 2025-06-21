# export PGUSER="your_postgres_user"
# export PGPASSWORD="your_postgres_password"

python3 tools/scripts/pet_scraper.py
. tools/db_loaders/load_all.sh  # update JWT_ADMIN and optionally BASE_URL
pg_dump -h localhost -d petify > backup.sql
