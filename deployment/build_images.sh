#!/bin/bash
services=(config-server discovery-server gateway auth-server feed image shelter) # chat reservations funding

for service in "${services[@]}"
do
    echo "Building image for service: $service..."
    mvn spring-boot:build-image -f app/backend/$service/pom.xml \
        -Dspring-boot.build-image.imageName=$ACR_LOGIN_SERVER/petify-$service:latest
    docker push $ACR_LOGIN_SERVER/petify-$service:latest
done
