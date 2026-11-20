import Combine
import Foundation

@MainActor
final class VideoStore: ObservableObject {
    @Published var query = ""
    @Published var history: [String]
    @Published var results: [Video] = []
    @Published var showingResults = false
    @Published var isSearching = false
    @Published var searchMessage = "没有找到结果"

    private var searchTask: Task<Void, Never>?
    private static let historyKey = "search_history"

    init() {
        history = Array((UserDefaults.standard.stringArray(forKey: Self.historyKey) ?? []).prefix(20))
        _ = UsageWindow.isActive()
    }

    func clearSearch() {
        searchTask?.cancel()
        searchTask = nil
        showingResults = false
        isSearching = false
    }

    func search(_ term: String) {
        let value = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { clearSearch(); return }
        searchTask?.cancel()
        query = value
        showingResults = true
        results = []
        isSearching = false
        guard UsageWindow.isActive() else {
            searchMessage = "网络不可用"
            return
        }
        remember(value)
        searchMessage = "没有找到结果"
        isSearching = true
        searchTask = Task {
            var failed = 0
            await withTaskGroup(of: [Video]?.self) { group in
                for source in Source.all {
                    group.addTask { try? await VideoAPI.search(value, source: source) }
                }
                for await batch in group {
                    if Task.isCancelled { break }
                    if let batch {
                        results.append(contentsOf: batch)
                    } else {
                        failed += 1
                    }
                }
            }
            if !Task.isCancelled {
                searchMessage = failed == Source.all.count ? "所有片源请求失败，请检查网络或片源" : "没有找到结果"
                isSearching = false
            }
        }
    }

    func deleteHistory(_ value: String) {
        history.removeAll { $0 == value }
        UserDefaults.standard.set(history, forKey: Self.historyKey)
    }

    func clearHistory() {
        history = []
        UserDefaults.standard.set(history, forKey: Self.historyKey)
    }

    private func remember(_ value: String) {
        history.removeAll { $0 == value }
        history.insert(value, at: 0)
        history = Array(history.prefix(20))
        UserDefaults.standard.set(history, forKey: Self.historyKey)
    }
}
