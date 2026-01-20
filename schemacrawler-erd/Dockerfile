FROM eclipse-temurin:17-jdk-jammy

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    postgresql-client \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# Install Liquibase
ENV LIQUIBASE_VERSION=4.25.1
RUN curl -L https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.tar.gz \
    | tar -xzC /opt && \
    ln -s /opt/liquibase /usr/local/bin/liquibase

# Install SchemaCrawler
ENV SCHEMACRAWLER_VERSION=16.21.2
RUN mkdir -p /opt/schemacrawler && \
    cd /opt/schemacrawler && \
    curl -sLO "https://github.com/schemacrawler/SchemaCrawler/releases/download/v${SCHEMACRAWLER_VERSION}/schemacrawler-${SCHEMACRAWLER_VERSION}-bin.zip" && \
    unzip -q "schemacrawler-${SCHEMACRAWLER_VERSION}-bin.zip" && \
    rm "schemacrawler-${SCHEMACRAWLER_VERSION}-bin.zip" && \
    chmod +x schemacrawler-${SCHEMACRAWLER_VERSION}-bin/bin/schemacrawler.sh

ENV PATH="/opt/schemacrawler/schemacrawler-${SCHEMACRAWLER_VERSION}-bin/bin:${PATH}"

WORKDIR /workspace
