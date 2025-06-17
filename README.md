# Petify

## CI Status
[![Backend Code Quality Checks](https://github.com/wiktorszewczyk/Petify/actions/workflows/checks.yml/badge.svg)](https://github.com/wiktorszewczyk/Petify/actions/workflows/checks.yml)
[![Publish Reports to GitHub Pages](https://github.com/wiktorszewczyk/Petify/actions/workflows/reporting.yml/badge.svg)](https://github.com/wiktorszewczyk/Petify/actions/workflows/reporting.yml)

## Documentation
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-222222?style=for-the-badge&logo=GitHub%20Pages&logoColor=white)](https://wiktorszewczyk.github.io/Petify/)

## Setup

### Backend
Service run order:
1. Config Server
2. Discovery Server
3. Other Services (e.g., Pet Service, User Service)
4. Gateway

```sh
# for each service in seperate terminal
cd app/backend/<service_name>
mvn spring-boot:run
```

#### Backend checks
```sh
# Align POM formatting
mvn tidy:pom -f app/backend/pom.xml

# Validate stage (POM formatting, Checkstyle)
mvn validate -f app/backend/pom.xml

# Compile Stage
mvn compile -f app/backend/pom.xml

# Test Stage
mvn test -f app/backend/pom.xml

# Verify Stage (PMD, SpotBugs, JaCoCo)
mvn verify -f app/backend/pom.xml
```
