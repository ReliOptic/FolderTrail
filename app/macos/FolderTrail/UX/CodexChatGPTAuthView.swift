import AppKit
import SwiftUI

struct CodexChatGPTOAuthView: View {
    enum Style {
        case full
        case compact
    }

    var style: Style = .full
    var onRecheck: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.xs) {
            if style == .full {
                Text("로컬 도우미")
                    .font(FolderTrailDesign.Typography.body.weight(.semibold))
                Label("Codex / ChatGPT OAuth", systemImage: "terminal")
                    .font(FolderTrailDesign.Typography.meta.weight(.semibold))
                Text("OpenRouter와 별개 로그인입니다. OpenRouter는 AI 제공자 연결이고, Codex / ChatGPT OAuth는 로컬 도우미를 터미널/브라우저에서 연결합니다. 토큰을 FolderTrail에 붙여넣지 마세요.")
                    .font(FolderTrailDesign.Typography.meta)
                    .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
            }

            HStack(spacing: FolderTrailDesign.Spacing.sm) {
                Button(style == .compact ? "로그인" : "Codex / ChatGPT 로그인 열기") {
                    CodexLoginHandoff.openInTerminal()
                }

                if let onRecheck {
                    Button("다시 확인") {
                        onRecheck()
                    }
                }
            }
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum CodexLoginHandoff {
    static func openInTerminal() {
        let commandURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("foldertrail-codex-login-\(UUID().uuidString).command")
        let script = """
        #!/bin/zsh
        echo "FolderTrail Codex / ChatGPT OAuth"
        echo "A browser may open to finish OAuth. This is separate from OpenRouter."
        echo
        codex login
        echo
        echo "로그인이 끝나면 이 창을 닫고 FolderTrail에서 다시 확인을 누르세요."
        read -r "?Press return to close..."
        """

        do {
            try script.write(to: commandURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: commandURL.path)
            NSWorkspace.shared.open(commandURL)
        } catch {
            NSSound.beep()
        }
    }
}
