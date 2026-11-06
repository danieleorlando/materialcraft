#!/bin/sh
# Vercel build: the build image has no Flutter, so it is downloaded here at the
# same version used for development. Locally, the Flutter on PATH is used.
set -e
FLUTTER_VERSION=3.47.9
cd "$(dirname "$0")/.."
if [ -n "$VERCEL" ]; then
  if [ ! -x .flutter/bin/flutter ]; then
    git clone --depth 1 --branch "$FLUTTER_VERSION" \
      https://github.com/flutter/flutter.git .flutter
  fi
  FLUTTER=.flutter/bin/flutter
  "$FLUTTER" config --no-analytics >/dev/null
else
  FLUTTER=flutter
fi
"$FLUTTER" --version
"$FLUTTER" pub get
"$FLUTTER" build web --release
