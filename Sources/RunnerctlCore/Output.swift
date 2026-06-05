import Foundation

/// Writes command output.
protocol OutputWriting {
    /// Writes a string and appends a trailing newline when needed.
    func write(_ text: String)
}

/// Standard output writer.
struct StandardOutput: OutputWriting {
    init() {}

    func write(_ text: String) {
        FileHandle.standardOutput.writeOutput(text)
    }
}

/// Standard error writer.
struct StandardError: OutputWriting {
    init() {}

    func write(_ text: String) {
        FileHandle.standardError.writeOutput(text)
    }
}

extension OutputWriting {
    /// Encodes and writes a JSON value.
    func writeJSON<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        guard let text = String(data: data, encoding: .utf8) else {
            throw RunnerctlError.unexpected("Could not encode JSON output.")
        }
        write(text)
    }
}

private extension FileHandle {
    func writeOutput(_ text: String) {
        let finalText = text.hasSuffix("\n") ? text : "\(text)\n"
        if let data = finalText.data(using: .utf8) {
            write(data)
        }
    }
}

/// Captures output in tests.
final class CapturingOutput: OutputWriting {
    private(set) var text = ""

    func write(_ text: String) {
        self.text += text.hasSuffix("\n") ? text : "\(text)\n"
    }
}
