import Foundation
import JSONSchema

struct StartResponse: Encodable {
  let version: Int
  let implementation: Implementation

  struct Implementation: Encodable {
    let language: String = "swift"
    let name = "swift-json-schema"
    let version = jsonSchemaVersion
    let dialects: Set<String>
    let homepage = "https://github.com/ajevans99/swift-json-schema"
    let issues = "https://github.com/ajevans99/swift-json-schema/issues"
    let source = "https://github.com/ajevans99/swift-json-schema"
    let documentation =
      "https://swiftpackageindex.com/ajevans99/swift-json-schema/main/documentation/jsonschema"
    let os: String = {
      #if os(Linux)
        return "Linux"
      #elseif os(macOS)
        return "macOS"
      #else
        return "Unknown"
      #endif
    }()
    let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
    let languageVersion = swiftVersion

    enum CodingKeys: String, CodingKey {
      case language, name, version, dialects, homepage, issues, source
      case documentation, os
      case osVersion = "os_version"
      case languageVersion = "language_version"
    }
  }
}

struct DialectResponse: Encodable {
  let ok: Bool
}

enum RunResponse: Encodable {
  case result(Result)
  case skipped(Skipped)
  case executionError(ExecutionError)

  var seq: JSONValue {
    switch self {
    case .result(let result):
      return result.seq
    case .skipped(let skipped):
      return skipped.seq
    case .executionError(let error):
      return error.seq
    }
  }

  private enum CodingKeys: String, CodingKey {
    case seq
    case results, skipped, message, errored, context
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(seq, forKey: .seq)

    switch self {
    case .result(let result):
      try container.encode(result.results, forKey: .results)
    case .skipped(let skipped):
      try container.encode(skipped.skipped, forKey: .skipped)
      try container.encode(skipped.message, forKey: .message)
    case .executionError(let error):
      try container.encode(error.errored, forKey: .errored)
      try container.encode(error.context, forKey: .context)
    }
  }

  struct Result: Encodable {
    let seq: JSONValue
    let results: [TestResult]
  }

  struct Skipped: Codable {
    let seq: JSONValue
    let skipped: Bool
    let message: String
  }

  struct ExecutionError: Codable {
    let seq: JSONValue
    let errored: Bool
    let context: ErrorContext
  }
}

enum TestResult: Encodable {
  case executed(Executed)
  case skipped(Skipped)
  case executionError(ExecutionError)

  private enum CodingKeys: String, CodingKey {
    case valid, annotations, skipped, message, errored, context
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .executed(let executed):
      try container.encode(executed.valid, forKey: .valid)
      if let annotations = executed.annotations {
        try container.encode(annotations, forKey: .annotations)
      }
    case .skipped(let skipped):
      try container.encode(skipped.skipped, forKey: .skipped)
      try container.encodeIfPresent(skipped.message, forKey: .message)
    case .executionError(let error):
      try container.encode(error.errored, forKey: .errored)
      try container.encodeIfPresent(error.context, forKey: .context)
    }
  }

  struct Executed: Encodable {
    let valid: Bool
    let annotations: [BowtieAnnotation]?

    init(valid: Bool, annotations: [BowtieAnnotation]? = nil) {
      self.valid = valid
      self.annotations = annotations
    }
  }

  struct Skipped: Codable {
    let skipped: Bool
    let message: String?
  }

  struct ExecutionError: Codable {
    let errored: Bool
    let context: ErrorContext?
  }
}

struct ErrorContext: Codable {
  let message: String?
  let traceback: String?
}

struct BowtieAnnotation: Encodable {
  let keyword: String
  let instanceLocation: String
  let keywordLocation: String
  let annotation: JSONValue

  init(_ collected: AnyAnnotation) {
    self.keyword = collected.keyword
    self.instanceLocation = collected.instanceLocation.jsonPointerString
    self.keywordLocation = "#" + collected.schemaLocation.jsonPointerString
    self.annotation = collected.jsonValue
  }
}
