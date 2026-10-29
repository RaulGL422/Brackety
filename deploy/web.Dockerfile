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
WORKDIR /src
COPY packages packages
COPY ${APP} ${APP}
WORKDIR /src/${APP}
RUN test -n "$API_BASE_URL" || (echo "API_BASE_URL build arg is required" && exit 1)
RUN flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL="$API_BASE_URL"

FROM nginx:1.30.6-alpine
ARG APP
COPY deploy/nginx/security-headers.conf /etc/nginx/security-headers.conf
COPY deploy/nginx/web.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/${APP}/build/web /usr/share/nginx/html
