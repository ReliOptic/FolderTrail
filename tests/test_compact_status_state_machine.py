import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
STATE_MACHINE = APP / "Execution" / "CompactStatusStateMachine.swift"
STATUS_VIEW = APP / "UX" / "CompactStatusView.swift"
EXECUTOR = APP / "Execution" / "SafeExecutor.swift"
ADAPTER = APP / "Intelligence" / "OpenRouterPlannerAdapter.swift"
MANIFEST = APP / "Intelligence" / "ManifestBuilder.swift"
KEYCHAIN = APP / "Safety" / "OpenRouterKeychain.swift"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"


class CompactStatusStateMachineTests(unittest.TestCase):
    def test_issue_12_status_state_machine(self):
        self.assertTrue(STATE_MACHINE.exists(), "missing Execution/CompactStatusStateMachine.swift")
        self.assertTrue(STATUS_VIEW.exists(), "missing UX/CompactStatusView.swift")

        machine = STATE_MACHINE.read_text(encoding="utf-8")
        view = STATUS_VIEW.read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")

        self.assertIn("@MainActor", machine)
        self.assertIn("@Published", machine)
        for state in ["idle", "preflight", "copying_workspace", "scanning", "planning", "organizing", "writing_trail", "done", "needs_review", "error"]:
            self.assertIn(state, machine)
        self.assertIn("minimumStagedDuration", machine)
        self.assertIn("10", machine)
        self.assertIn("counters", machine)
        self.assertIn("CompactStatusView", view)
        self.assertIn("작업 중단", view)
        self.assertNotIn("%", view)
        self.assertNotIn("rawProvider", view)
        self.assertIn("CompactStatusStateMachine.swift", project)
        self.assertIn("CompactStatusView.swift", project)

        smoke = textwrap.dedent(
            r'''
            import Foundation

            func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
                if !condition() {
                    FileHandle.standardError.write(Data(message.utf8))
                    FileHandle.standardError.write(Data("\n".utf8))
                    exit(1)
                }
            }

            @main
            struct Smoke {
                @MainActor
                static func main() {
                    let machine = CompactStatusStateMachine()
                    expect(machine.state == .idle, "starts idle")
                    expect(machine.counters == nil, "counters start nil")
                    machine.beginPreflight()
                    machine.beginCopyingWorkspace()
                    machine.beginScanning()
                    machine.beginProviderExecution()
                    expect(machine.state == .planning, "provider starts planning")
                    machine.advanceStagedActivity(elapsed: 11)
                    expect(machine.state == .organizing, "long execution advances organizing")
                    machine.advanceStagedActivity(elapsed: 12)
                    expect(machine.state == .writing_trail, "long execution advances writing trail")

                    let fast = CompactStatusStateMachine()
                    fast.beginProviderExecution()
                    fast.finish(trail: ExecutionTrail(plan_version: "0.1", interrupted: false, action_logs: [], rejected_actions: [], validation_errors: []), elapsed: 3)
                    expect(fast.state == .done, "fast run should skip staged states and finish")
                    expect(fast.counters != nil, "counters appear only at completion")

                    let review = CompactStatusStateMachine()
                    review.finish(trail: ExecutionTrail(plan_version: "0.1", interrupted: false, action_logs: [], rejected_actions: [RejectedAction(type: "delete", reason: "no")], validation_errors: []), elapsed: 12)
                    expect(review.state == .needs_review, "rejections should need review")
                }
            }
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "CompactStatusSmoke"
            main.write_text(smoke, encoding="utf-8")
            subprocess.run(
                [
                    "swiftc",
                    "-parse-as-library",
                    "-warnings-as-errors",
                    "-target",
                    "arm64-apple-macosx14.0",
                    str(MANIFEST),
                    str(KEYCHAIN),
                    str(ADAPTER),
                    str(EXECUTOR),
                    str(STATE_MACHINE),
                    str(main),
                    "-o",
                    str(exe),
                ],
                check=True,
                cwd=ROOT,
            )
            subprocess.run([str(exe)], check=True, cwd=ROOT)


if __name__ == "__main__":
    unittest.main()
