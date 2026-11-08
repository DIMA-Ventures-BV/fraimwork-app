// fraimwork: appended to CLI/cmux.swift by scripts/fraimwork-rebrand.py at build time.
// When the CLI runs under the name `fraimwork`, help output and error text name fraimwork.
// Paths (~/.config/cmux), file names (cmux.json) and variables (CMUX_SOCKET_PATH) stay as they are.
import Foundation

enum FraimworkOutputBrand {
    static let name = "fraimwork"

    static var active: Bool {
        let invoked = CommandLine.arguments.first.map { ($0 as NSString).lastPathComponent } ?? ""
        return invoked == name
    }

    static func isHelpInvocation(_ args: [String]) -> Bool {
        let rest = args.dropFirst()
        return rest.isEmpty || rest.contains { $0 == "--help" || $0 == "-h" || $0 == "help" }
    }

    private static let pattern = try! NSRegularExpression(
        pattern: #"(?<![A-Za-z0-9_./~-])cmux(?![A-Za-z0-9_/-])(?!\.[A-Za-z0-9_])"#,
        options: [.caseInsensitive]
    )

    static func rename(_ text: String) -> String {
        let range = NSRange(text.startIndex..., in: text)
        return pattern.stringByReplacingMatches(in: text, range: range, withTemplate: name)
    }

    static func brand(_ text: String) -> String {
        active ? rename(text) : text
    }

    nonisolated(unsafe) private static var captureFD: Int32 = -1
    nonisolated(unsafe) private static var savedStdoutFD: Int32 = -1

    /// Runs `body`; for a help invocation under the fraimwork name, its standard output is renamed.
    static func run(_ body: () async throws -> Void) async throws {
        guard active, isHelpInvocation(CommandLine.arguments), beginCapture() else {
            try await body()
            return
        }
        defer { finishCapture() }
        try await body()
    }

    private static func beginCapture() -> Bool {
        fflush(stdout)
        let path = NSTemporaryDirectory() + "fraimwork-help-\(getpid()).txt"
        let fd = open(path, O_RDWR | O_CREAT | O_TRUNC, 0o600)
        guard fd >= 0 else { return false }
        unlink(path)
        let saved = dup(STDOUT_FILENO)
        guard saved >= 0, dup2(fd, STDOUT_FILENO) >= 0 else {
            close(fd)
            if saved >= 0 { close(saved) }
            return false
        }
        captureFD = fd
        savedStdoutFD = saved
        // A help path that calls exit() still gets its text out.
        atexit { FraimworkOutputBrand.finishCapture() }
        return true
    }

    static func finishCapture() {
        guard captureFD >= 0 else { return }
        fflush(stdout)
        let fd = captureFD
        captureFD = -1
        dup2(savedStdoutFD, STDOUT_FILENO)
        close(savedStdoutFD)
        savedStdoutFD = -1
        lseek(fd, 0, SEEK_SET)
        let data = FileHandle(fileDescriptor: fd, closeOnDealloc: true).readDataToEndOfFile()
        let text = rename(String(decoding: data, as: UTF8.self))
        FileHandle.standardOutput.write(Data(text.utf8))
    }
}
