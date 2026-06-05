import Foundation
import RunnerctlCore

let app = RunnerctlApp()
let exitCode = app.run(arguments: Array(CommandLine.arguments.dropFirst()))
exit(Int32(exitCode))
