import Foundation

/// Result from running a subprocess.
struct CommandResult: Equatable {
    var exitCode: Int32
    var output: String
}

/// Runs system commands.
protocol CommandExecuting {
    /// Executes a command and captures combined stdout/stderr.
    func run(_ executable: String, arguments: [String]) -> CommandResult
}

/// Process-backed command executor.
struct ProcessCommandExecutor: CommandExecuting {
    func run(_ executable: String, arguments: [String]) -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return CommandResult(exitCode: process.terminationStatus, output: String(data: data, encoding: .utf8) ?? "")
        } catch {
            return CommandResult(exitCode: 127, output: "\(error)")
        }
    }
}
