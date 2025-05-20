# Petify

## CI Status
[![Backend Code Quality Checks](https://github.com/wiktorszewczyk/Petify/actions/workflows/checks.yml/badge.svg)](https://github.com/wiktorszewczyk/Petify/actions/workflows/checks.yml)
[![Publish Reports to GitHub Pages](https://github.com/wiktorszewczyk/Petify/actions/workflows/reporting.yml/badge.svg)](https://github.com/wiktorszewczyk/Petify/actions/workflows/reporting.yml)

## Documentation
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-222222?style=for-the-badge&logo=GitHub%20Pages&logoColor=white)](https://wiktorszewczyk.github.io/Petify/)

## Setup

### Backend

```

```

#### Backend checks
```
# Align POM formatting
mvn tidy:pom -f app/backend/pom.xml

# Validate stage (POM formatting, Checkstyle)
mvn validate -f app/backend/pom.xml

# Compile Stage
mvn compile -f app/backend/pom.xml

# Test Stage
mvn test -f app/backend/pom.xml -pl '!:auth-server'

# Verify Stage (PMD, SpotBug, JaCoCo)
mvn verify -f app/backend/pom.xml -pl '!:auth-server'
```
