# Petify

## CI Status
[![Backend Code Quality Checks](https://github.com/wiktorszewczyk/Petify/actions/workflows/checks.yml/badge.svg)](https://github.com/wiktorszewczyk/Petify/actions/workflows/checks.yml)
[![Publish Reports to GitHub Pages](https://github.com/wiktorszewczyk/Petify/actions/workflows/reporting.yml/badge.svg)](https://github.com/wiktorszewczyk/Petify/actions/workflows/reporting.yml)

## Documentation
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-222222?style=for-the-badge&logo=GitHub%20Pages&logoColor=white)](https://wiktorszewczyk.github.io/Petify/)

## Download Android APK
[![Android APK Download](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://raw.githubusercontent.com/wiktorszewczyk/Petify/refs/heads/main/app/mobile/petify.apk)

# Setup

## Backend

### Running Backend
Service run order:
1. Config Server
2. Discovery Server
3. Other Services (e.g., Auth Service, Shelter Service)
4. Gateway

```sh
# For each service in seperate terminal
cd app/backend/<service_name>
mvn spring-boot:run
```

### Backend checks for Pull Requests
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

## Frontend

### Tech Stack

- Node.js
- React
- Vite 
- Bootstrap

### Getting Started

1. Make sure you have the following items installed before starting the application:

- [Node.js](https://nodejs.org)
- [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) (should be supplied with Node.js)

2. Open IDE and navigate to the cloned repository and select the "frontend" directory.
```sh
cd app/frontend
```

3. Install the required packages:
```sh
npm install
```

4. (Optional) Set up environment variables by creating a new file named `.env` in the "frontend" directory  and add the following content:

```env
VITE_API_BASE_URL=http://localhost:8222
```
 
### Running Application

1. From the "frontend" directory, start the application:
```sh
npm run dev
```

2. The frontend application will be available at `http://localhost:5173` in your web browser.
