FROM dart:stable AS build

WORKDIR /app

# The standalone WebSocket server only uses standard dart:io & dart:convert (no Flutter required)
COPY server/ ./server/
RUN dart compile exe server/bin/server.dart -o /app/server_bin

FROM debian:bookworm-slim
COPY --from=build /app/server_bin /server

ENV PORT=8081
EXPOSE 8081

CMD ["/server"]
