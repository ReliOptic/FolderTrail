import Foundation

enum FolderTrailRunState: Equatable {
    case promptReceived
    case workspaceReady
    case manifestBuilt
    case planReady
    case executing
    case trailWritten
    case done
}

struct FolderTrailRunResult: Equatable {
    let prompt: String
    let sourceFolderURL: URL
    let workspaceURL: URL
    let manifest: FolderManifest
    let plan: ActionPlan
    let trail: ExecutionTrail
    let artifacts: TrailArtifacts
    let states: [FolderTrailRunState]
}

final class FolderTrailRunPipeline {
    typealias StateObserver = (FolderTrailRunState) -> Void
    typealias CopyWorkspace = (URL) throws -> WorkspaceCopyResult
    typealias BuildManifest = (URL, String) throws -> FolderManifest
    typealias PlanActions = (String, FolderManifest) async throws -> ActionPlan
    typealias ExecutePlan = (ActionPlan, URL) throws -> ExecutionTrail
    typealias WriteTrail = (ExecutionTrail, URL, String, String, ActionPlan, FolderManifest) throws -> TrailArtifacts

    private let copyWorkspace: CopyWorkspace
    private let buildManifest: BuildManifest
    private let planActions: PlanActions
    private let executePlan: ExecutePlan
    private let writeTrail: WriteTrail
    private let onState: StateObserver

    static func offlineMock(onState: @escaping StateObserver = { _ in }) -> FolderTrailRunPipeline {
        FolderTrailRunPipeline(planner: MockPlannerAdapter(), onState: onState)
    }

    init(
        workspaceCopyService: WorkspaceCopyService = WorkspaceCopyService(),
        manifestBuilder: ManifestBuilder = ManifestBuilder(),
        planner: PlannerAdapter,
        trailWriter: TrailWriter = TrailWriter(),
        onState: @escaping StateObserver = { _ in }
    ) {
        self.copyWorkspace = { sourceFolderURL in
            try workspaceCopyService.copyWorkspace(sourceFolderURL: sourceFolderURL)
        }
        self.buildManifest = { workspaceURL, sourceFolderPath in
            try manifestBuilder.build(
                workspaceURL: workspaceURL,
                sourceFolderPath: sourceFolderPath
            )
        }
        self.planActions = { prompt, manifest in
            try await planner.plan(prompt: prompt, manifest: manifest)
        }
        self.executePlan = { plan, workspaceURL in
            try SafeExecutor(workspaceURL: workspaceURL).execute(plan)
        }
        self.writeTrail = { trail, workspaceURL, sourceFolderPath, prompt, plan, manifest in
            try trailWriter.write(
                trail: trail,
                workspaceURL: workspaceURL,
                sourceFolderPath: sourceFolderPath,
                userPrompt: prompt,
                provider: plan.provider,
                model: plan.model,
                manifestDetailLevel: manifest.detail_level.rawValue,
                summaryText: plan.summary_ko
            )
        }
        self.onState = onState
    }

    init(
        copyWorkspace: @escaping CopyWorkspace,
        buildManifest: @escaping BuildManifest,
        planActions: @escaping PlanActions,
        executePlan: @escaping ExecutePlan,
        writeTrail: @escaping WriteTrail,
        onState: @escaping StateObserver = { _ in }
    ) {
        self.copyWorkspace = copyWorkspace
        self.buildManifest = buildManifest
        self.planActions = planActions
        self.executePlan = executePlan
        self.writeTrail = writeTrail
        self.onState = onState
    }

    func run(prompt: String, sourceFolderURL: URL) async throws -> FolderTrailRunResult {
        var states: [FolderTrailRunState] = []

        func emit(_ state: FolderTrailRunState) {
            states.append(state)
            onState(state)
        }

        emit(.promptReceived)

        let workspaceResult = try copyWorkspace(sourceFolderURL)
        emit(.workspaceReady)

        let manifest = try buildManifest(
            workspaceResult.workspaceURL,
            workspaceResult.sourceFolderURL.path
        )
        emit(.manifestBuilt)

        let plan = try await planActions(prompt, manifest)
        emit(.planReady)

        emit(.executing)
        let trail = try executePlan(plan, workspaceResult.workspaceURL)

        let artifacts = try writeTrail(
            trail,
            workspaceResult.workspaceURL,
            workspaceResult.sourceFolderURL.path,
            prompt,
            plan,
            manifest
        )
        emit(.trailWritten)
        emit(.done)

        return FolderTrailRunResult(
            prompt: prompt,
            sourceFolderURL: workspaceResult.sourceFolderURL,
            workspaceURL: workspaceResult.workspaceURL,
            manifest: manifest,
            plan: plan,
            trail: trail,
            artifacts: artifacts,
            states: states
        )
    }
}
