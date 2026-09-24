FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe server/bin/server.dart -o /app/server_bin

FROM debian:bookworm-slim
COPY --from=build /app/server_bin /server

ENV PORT=8081
EXPOSE 8081

CMD ["/server"]
