import Foundation

// Loads the bundled scenes.json once and caches it. Throws a visible
// error early if the JSON is missing or malformed so we catch content
// regressions in development.

final class SceneRepository {
    static let shared = SceneRepository()

    let catalog: SceneCatalog

    private init() {
        guard let url = Bundle.main.url(forResource: "scenes", withExtension: "json") else {
            fatalError("scenes.json not found in bundle. Check it's in Speak/Resources/ and marked as a resource.")
        }
        do {
            let data = try Data(contentsOf: url)
            self.catalog = try JSONDecoder().decode(SceneCatalog.self, from: data)
        } catch {
            fatalError("Failed to decode scenes.json: \(error)")
        }
    }

    var scenes: [SpeakScene] { catalog.scenes }
    var categories: [SceneCategory] { catalog.categories }
    var examTopics: [SceneCategory] { catalog.examTopics ?? [] }   // 剑桥话题 chips

    // 剑桥考试顺序(分段控件)
    let exams = ["KET", "PET", "FCE"]

    func scene(id: String) -> SpeakScene? {
        catalog.scenes.first { $0.id == id }
    }

    // Used by HomeScreen to pick the featured "今日练习" card.
    var featuredScene: SpeakScene {
        catalog.scenes.first(where: { $0.isFeatured }) ?? catalog.scenes[0]
    }

    // Quick picks for the home screen's 常练场景 grid.
    var quickScenes: [SpeakScene] {
        let ids = ["self-intro", "directions", "taxi", "checkout"]
        return ids.compactMap { id in catalog.scenes.first(where: { $0.id == id }) }
    }
}
