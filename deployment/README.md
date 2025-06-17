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
scp -i ~/.ssh/petify.pem deployment/docker-compose.yml deployment/.env petify@backend.petify.x5z1fu.com:/home/petify

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
