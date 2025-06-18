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
mvn test -f app/backend/pom.xml

# Verify Stage (PMD, SpotBugs, JaCoCo)
mvn verify -f app/backend/pom.xml
```

### Frontend

#### Tech Stack

- Node.js
- React
- Vite 
- Bootstrap

#### Getting Started

1. Make sure you have the following items installed before starting the application:

- [Git](https://git-scm.com/)
- [Node.js](https://nodejs.org)
- [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm): Node Package Manager (supplied with Node.js)

2. Clone the repository to your local machine:
```sh
git clone https://github.com/wiktorszewczyk/Petify.git
```

3. Open IDE and navigate to the cloned repository and select the "frontend" directory.
```sh
cd app/frontend
```

4. Install the required packages:
```sh
npm install
```

<!-- 5. Set up environment variables by creating a new file named `.env` in the "frontend" directory  and add the following content:

```env
VITE_API_BASE_URL=http://localhost:8222
``` -->
 
#### Running Application

1. From the "frontend" directory, start the application:
```sh
npm run dev
```

2. The frontend application will be available at `http://localhost:5173` in your web browser.
