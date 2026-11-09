FROM dart:stable AS build
WORKDIR /app
COPY pubspec.yaml ./
RUN dart pub get
COPY . .
RUN dart pub get --offline

EXPOSE 8080
CMD ["dart", "run", "bin/server.dart"]
