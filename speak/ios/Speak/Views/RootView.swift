import SwiftUI

// Tab bar container. 4 top-level destinations, matching the web design.
// Navigation inside each tab is handled by NavigationStack per-tab.

struct RootView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var store: AppStore

    @State private var homePath  = NavigationPath()
    @State private var scenesPath = NavigationPath()
    @State private var reviewPath = NavigationPath()

    var body: some View {
        let p = theme.palette
        TabView(selection: Binding(
            get: { store.selectedTab },
            set: { newValue in
                Haptics.select()
                store.selectedTab = newValue
            })
        ) {
            // Pass non-filled SF Symbol names. iOS 17+ TabView swaps to the
            // .fill variant automatically when the tab is selected — matches
            // how Apple's own Books / Fitness / Music tab bars feel.
            NavigationStack(path: $homePath) {
                HomeScreen(path: $homePath)
            }
            .tabItem { Label("首页", systemImage: "house") }
            .tag(AppStore.Tab.home)

            NavigationStack(path: $scenesPath) {
                ScenesScreen(path: $scenesPath)
            }
            .tabItem { Label("场景馆", systemImage: "books.vertical") }
            .tag(AppStore.Tab.scenes)

            NavigationStack(path: $reviewPath) {
                ReviewScreen(path: $reviewPath)
            }
            .tabItem { Label("复练", systemImage: "clock.arrow.circlepath") }
            .tag(AppStore.Tab.review)
            .badge(store.reviewQueue.count)

            NavigationStack {
                MeScreen()
            }
            .tabItem { Label("我的", systemImage: "person") }
            .tag(AppStore.Tab.me)
        }
        .tint(p.accent)
        .background(p.bg.ignoresSafeArea())
        .task { Haptics.prepareAll() }
    }
}

// Route destinations — one enum so pushing from any screen goes through
// the same NavigationStack path.
//
// Every practice / result navigation carries a `tierLevel` so we know
// which difficulty bucket the user is working through. Older review
// items that pre-date tiers default to "beginner".
enum AppRoute: Hashable {
    case detail(sceneId: String)
    case practice(sceneId: String, tierLevel: String, filteredIndexes: [Int]?)
    // 对话对练:你演 userVoice 方("chris"=男 / "rosie"=女),对方句自动播,你的句录音评分。
    case drill(sceneId: String, tierLevel: String, userVoice: String)
    // 模拟考官:AI 演剑桥 Part 1 考官,自由问答(DeepSeek + SFSpeech 转写)。examinerVoice=rosie女/chris男。
    case exam(exam: String, topic: String, topicZh: String, examinerVoice: String)
    case result(sceneId: String, tierLevel: String)
}
