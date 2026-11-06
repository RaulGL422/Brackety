# The jar is architecture-independent: build it once on the runner's platform, not under emulation.
FROM --platform=$BUILDPLATFORM eclipse-temurin:27_35-jdk AS build
WORKDIR /src
COPY .mvn .mvn
COPY mvnw pom.xml ./
COPY src/main src/main
RUN --mount=type=cache,target=/root/.m2 ./mvnw -B -q package -Dmaven.test.skip=true \
    && cp target/brackety-server-*.jar /app.jar

FROM eclipse-temurin:27_35-jre
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --create-home --uid 10001 brackety
USER brackety
# Claude Code reads the lists of the participant import (docs/modulos/importacion-alumnos.md). Native
# installer (no Node.js), pinned so two builds carry the same CLI; it only reads with ANTHROPIC_API_KEY.
ARG CLAUDE_CODE_VERSION=2.1.316
ENV HOME=/home/brackety \
    PATH=/home/brackety/.local/bin:$PATH \
    DISABLE_AUTOUPDATER=1
RUN curl -fsSL https://claude.ai/install.sh | bash -s "$CLAUDE_CODE_VERSION" \
    && claude --version
COPY --from=build /app.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "/app/app.jar"]
