FROM eclipse-temurin:17-jdk-jammy

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    postgresql-client \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# Install Liquibase
ENV LIQUIBASE_VERSION=4.25.1
RUN curl -L https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz \
    | tar -xzC /opt && \
    ln -s /opt/liquibase /usr/local/bin/liquibase

# Install SchemaSpy
ENV SCHEMASPY_VERSION=6.2.4
RUN mkdir -p /opt/schemaspy && \
    cd /opt/schemaspy && \
    curl -sL "https://github.com/schemaspy/schemaspy/releases/download/v${SCHEMASPY_VERSION}/schemaspy-${SCHEMASPY_VERSION}.jar" > schemaspy.jar && \
    curl -sL "https://jdbc.postgresql.org/download/postgresql-42.7.1.jar" > postgresql.jar

WORKDIR /workspace
