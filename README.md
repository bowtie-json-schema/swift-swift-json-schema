# swift-swift-json-schema

A [Bowtie](https://github.com/bowtie-json-schema/bowtie) test harness.

Its image is published to `ghcr.io/bowtie-json-schema/swift-swift-json-schema` and run via `bowtie run -i swift-swift-json-schema`.

The image stages the release executable and its SwiftPM resource bundles from
`swift build -c release --show-bin-path` together in `/app`. The bundles must sit
beside the relocated executable; retaining the original `.build` tree elsewhere
does not satisfy every SwiftPM build system's resource accessor.

Every image build runs `smoke-test.sh` in the final runtime stage. It checks valid
and invalid schemas through a reference to the bundled Draft 2020-12 meta-schema,
including nested `$defs` and validation-vocabulary constraints. To run it against
an existing image:

```sh
docker run --rm -i --entrypoint sh IMAGE < smoke-test.sh
```
