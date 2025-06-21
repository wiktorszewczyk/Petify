# Prerequisites
1. WSL
2. Install [Docker Engine](https://docs.docker.com/engine/install/ubuntu/) on WSL and Azure VM
    - [Linux post installation](https://docs.docker.com/engine/install/linux-postinstall/)
3. Install [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux) on WSL and Azure VM
4. Login to Azure and then Azure ACR
    ```sh
    az login
    az acr login --name petify
    ```

# Building service images
```sh
. deployment/build_images.sh
```

# Running the services on Azure
```sh
# Copy docker-compose.yml and .env files to the VM
scp -i ~/.ssh/petify.pem deployment/docker-compose.yml deployment/.env test_data/backup.sql petify@backend.petify.x5z1fu.com:/home/petify

# Connect to the Azure VM
ssh -i ~/.ssh/petify.pem petify@backend.petify.x5z1fu.com

# Run services
clear; docker compose -f docker-compose.yml down; clear; docker compose -f docker-compose.yml up -d
```

# Debugging
```sh
# Container related logs
docker logs <container_name>
# Healthcheck related logs
docker inspect --format='{{json .State.Health}}' <container_name> | jq
```

# Creating and using an access token to the ACR
```sh
# Creating the access token
az acr scope-map create --name pullOnlyMap --registry petify --repository '*' content/read metadata/read --description "Read-only access to every repository in the registry"
az acr token create --name pullAccessToken --registry petify --scope-map pullOnlyMap --no-passwords
az acr token credential generate --name pullAccessToken --registry petify --password1 # --expiration-in-days 30

# Using the access token
echo "<TOKEN_PASSWORD>" | docker login petify-cwezgrfdd6ghehg8.azurecr.io --username pullAccessToken --password-stdin
docker compose -f deployment/docker-compose.yml up -d
```
