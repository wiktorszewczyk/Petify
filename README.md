# Petify

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
