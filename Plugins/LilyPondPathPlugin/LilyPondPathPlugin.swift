import PackagePlugin

@main
struct LilyPondPathPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        // Resolve the lilypond tool from the binary artifact via the target's dependencies
        let lilypondTool: Path
        if let t = try? context.tool(named: "lilypond") {
            lilypondTool = t.path
        } else {
            lilypondTool = Path("")
        }

        // Resolve our generator utility
        let gen = try context.tool(named: "lp-path-gen").path
        let outDir = context.pluginWorkDirectory

        return [
            .buildCommand(
                displayName: "Generate embedded lilypond path",
                executable: gen,
                arguments: ["--tool-path", lilypondTool.string, "--out", outDir.string],
                environment: [:],
                inputFiles: [],
                outputFiles: [outDir.appending("LilyPondEmbeddedPath.swift")]
            )
        ]
    }
}

