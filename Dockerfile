FROM swift:latest AS build
WORKDIR /app
COPY . .

# install jq only for the build stage
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends jq && \
    rm -rf /var/lib/apt/lists/*

# Extract the version of swift-json-schema from Package.resolved and write it to Version.swift
RUN SJS_VERSION=$(jq -r '.pins[]|select(.identity=="swift-json-schema")|.state.version' Package.resolved) \
 && SWIFT_VERSION=$(swift --version | head -n 1 | sed -E 's/.*Swift version ([^ ]+).*/\1/') \
 && echo "swift-json-schema @ $SJS_VERSION, swift @ $SWIFT_VERSION" \
 && printf "let swiftVersion = \"$SWIFT_VERSION\"\nlet jsonSchemaVersion = \"$SJS_VERSION\"\n" > Sources/BowtieJSONSchema/Version.swift

RUN swift build -c release \
 && BIN_PATH="$(swift build -c release --show-bin-path)" \
 && mkdir /runtime \
 && cp "$BIN_PATH/BowtieJSONSchema" /runtime/ \
 && find "$BIN_PATH" -maxdepth 1 -type d \
      \( -name '*.bundle' -o -name '*.resources' \) \
      -exec cp -R {} /runtime/ \; \
 && (test -d /runtime/swift-json-schema_JSONSchema.bundle \
     || test -d /runtime/swift-json-schema_JSONSchema.resources)

FROM swift:slim
WORKDIR /app
COPY --from=build /runtime/ .
COPY smoke-test.sh /tmp/smoke-test.sh
RUN sh /tmp/smoke-test.sh && rm /tmp/smoke-test.sh
CMD ["./BowtieJSONSchema"]
