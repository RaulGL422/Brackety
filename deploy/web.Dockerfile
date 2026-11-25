# Builds app/ or admin/ (APP) as a static Flutter web bundle served by nginx. Context: repo root.
FROM --platform=$BUILDPLATFORM debian:trixie-slim AS build
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch 3.47.8 https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:$PATH"
RUN flutter config --no-analytics && flutter precache --web

ARG APP
ARG API_BASE_URL
# true only in the debug images (docs/modulos/entornos.md): the admin's Scenarios tab.
ARG BRACKETY_DEBUG=false
# The release and commit it was built from, shown under the version (0.8.2-dev.7 · 8c525af).
ARG BRACKETY_VERSION=""
ARG BRACKETY_COMMIT=""
WORKDIR /src
COPY packages packages
COPY ${APP} ${APP}
COPY CHANGELOG.md CHANGELOG.md
WORKDIR /src/${APP}
# Debug images carry the list of changes for their «Cambios» screen (brackety_core ChangelogView).
RUN if [ "$BRACKETY_DEBUG" = true ]; then cp /src/CHANGELOG.md web/changelog.md; fi
RUN test -n "$API_BASE_URL" || (echo "API_BASE_URL build arg is required" && exit 1)
RUN flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL="$API_BASE_URL" \
    --dart-define=BRACKETY_DEBUG="$BRACKETY_DEBUG" --dart-define=BRACKETY_VERSION="$BRACKETY_VERSION" \
    --dart-define=BRACKETY_COMMIT="$BRACKETY_COMMIT"

FROM nginx:1.31.8-alpine
ARG APP
COPY deploy/nginx/security-headers.conf /etc/nginx/security-headers.conf
COPY deploy/nginx/web.conf /etc/nginx/conf.d/default.conf
COPY deploy/nginx/admin-api.conf /tmp/admin-api.conf
RUN mkdir -p /etc/nginx/app.d \
    && if [ "$APP" = "admin" ]; then mv /tmp/admin-api.conf /etc/nginx/app.d/; else rm /tmp/admin-api.conf; fi
COPY --from=build /src/${APP}/build/web /usr/share/nginx/html
