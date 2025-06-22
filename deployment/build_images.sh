#!/bin/bash

services=(config-server discovery auth-server chat feed funding image reservations shelter gateway)

for service in "${services[@]}"
do
    echo "Building image for service: $service..."
    mvn clean spring-boot:build-image -DskipTests \
        -f app/backend/$service/pom.xml \
        -Dspring-boot.build-image.builder=paketobuildpacks/builder-jammy-full \
        -Dspring-boot.build-image.imageName=$ACR_LOGIN_SERVER/petify-$service:latest
    if [ $? -ne 0 ]; then
        echo "Build failed for $service. Stopping loop."
        break
    fi

    docker push $ACR_LOGIN_SERVER/petify-$service:latest
    if [ $? -ne 0 ]; then
        echo "Docker push failed for $service. Stopping loop."
        break
    fi
done
