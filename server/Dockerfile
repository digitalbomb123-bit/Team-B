FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe server/bin/server.dart -o /app/server/bin/server

FROM debian:bookworm-slim
COPY --from=build /app/server/bin/server /server

ENV PORT=8081
EXPOSE 8081

CMD ["/server"]
