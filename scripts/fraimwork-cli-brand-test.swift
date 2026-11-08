// Test driver for scripts/fraimwork-cli-brand.swift. Built and run by scripts/fraimwork-cli-brand-test.sh.
// argv[1] selects the mode: "rename" checks cases; anything else prints sample help, then
// exits through exit() when argv contains "exit".
import Foundation

@main
struct Driver {
    static func main() async throws {
        let args = CommandLine.arguments
        if args.count > 1, args[1] == "rename" {
            let cases: [(String, String)] = [
                ("cmux - control cmux via Unix socket", "fraimwork - control fraimwork via Unix socket"),
                ("  cmux <path>  Open", "  fraimwork <path>  Open"),
                ("Run `cmux docs settings`.", "Run `fraimwork docs settings`."),
                ("Quit cmux.", "Quit fraimwork."),
                ("cmux를 다시", "fraimwork를 다시"),
                ("~/.config/cmux/cmux.json", "~/.config/cmux/cmux.json"),
                ("CMUX_SOCKET_PATH", "CMUX_SOCKET_PATH"),
                ("cmux-dev and com.cmux.app", "cmux-dev and com.cmux.app"),
                ("https://cmux.com/docs", "https://cmux.com/docs"),
            ]
            var failed = 0
            for (input, expected) in cases {
                let got = FraimworkOutputBrand.rename(input)
                if got != expected {
                    print("FAIL rename: \(input) -> \(got), expected \(expected)")
                    failed += 1
                }
            }
            print(failed == 0 ? "rename ok" : "rename failed")
            exit(failed == 0 ? 0 : 1)
        }
        try await FraimworkOutputBrand.run {
            print("cmux - control cmux via Unix socket")
            print("Config: ~/.config/cmux/cmux.json")
            if args.contains("exit") { exit(0) }
        }
        print("after: cmux")
    }
}
