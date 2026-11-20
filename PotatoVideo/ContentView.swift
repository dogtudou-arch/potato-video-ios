import SwiftUI

private enum Theme {
    static let ink = Color(red: 25 / 255, green: 52 / 255, blue: 59 / 255)
    static let muted = Color(red: 76 / 255, green: 104 / 255, blue: 113 / 255)
    static let coral = Color(red: 1, green: 110 / 255, blue: 88 / 255)
    static let teal = Color(red: 35 / 255, green: 169 / 255, blue: 154 / 255)
}

struct FrostedBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Image("Background")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .blur(radius: 22)
                .overlay(Color.white.opacity(0.47))
                .clipped()
        }
        .ignoresSafeArea()
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: VideoStore
    @State private var editingHistory = false
    @State private var confirmingDelete = false
    @FocusState private var searchFocused: Bool

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        NavigationStack {
            ZStack {
                FrostedBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(spacing: 10) {
                            Image("Dog")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 50)
                                .frame(width: 60, height: 60)
                                .background(.white.opacity(0.7))
                                .clipShape(Circle())
                            Text("土豆视频")
                                .font(.system(size: 27, weight: .bold))
                                .foregroundStyle(Theme.ink)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)

                        HStack(spacing: 10) {
                            TextField("你想看什么", text: $store.query)
                                .focused($searchFocused)
                                .submitLabel(.search)
                                .onSubmit(runSearch)
                                .padding(.horizontal, 15)
                                .frame(height: 54)
                                .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 18))
                                .onChange(of: store.query) { value in
                                    if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        store.clearSearch()
                                        editingHistory = false
                                    }
                                }
                            Button("搜索", action: runSearch)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 82, height: 54)
                                .background(Theme.coral, in: RoundedRectangle(cornerRadius: 15))
                        }

                        if store.showingResults {
                            resultsSection
                        } else if !store.history.isEmpty {
                            historySection
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 36)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog("删除全部搜索历史？", isPresented: $confirmingDelete) {
                Button("全部删除", role: .destructive) {
                    store.clearHistory()
                    editingHistory = false
                }
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("搜索历史")
                    .font(.system(size: 19, weight: .bold))
                Spacer()
                if editingHistory {
                    Button("全部删除") { confirmingDelete = true }
                        .foregroundStyle(Theme.muted)
                    Button("完成") { editingHistory = false }
                } else {
                    Button { editingHistory = true } label: {
                        Image(systemName: "trash")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("编辑搜索历史")
                }
            }
            .foregroundStyle(Theme.ink)
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(store.history, id: \.self) { item in
                    HStack {
                        Button {
                            if !editingHistory {
                                store.query = item
                                runSearch()
                            }
                        } label: {
                            Text(item)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if editingHistory {
                            Button { store.deleteHistory(item) } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.muted)
                            }
                            .accessibilityLabel("删除" + item)
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 10)
                    .frame(height: 48)
                }
            }
        }
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("搜索结果")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if store.isSearching && !store.results.isEmpty {
                    ProgressView().tint(Theme.coral)
                }
            }
            if store.results.isEmpty {
                if store.isSearching {
                    ProgressView()
                        .tint(Theme.coral)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                } else {
                    Text(store.searchMessage)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.muted)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
                }
            } else {
                ForEach(store.results.sorted { $0.title < $1.title }) { video in
                    NavigationLink(destination: DetailView(video: video)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(video.title)
                                .font(.system(size: 16, weight: .medium))
                            if !video.details.isEmpty {
                                Text(video.details)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func runSearch() {
        searchFocused = false
        store.search(store.query)
    }
}

struct DetailView: View {
    let video: Video
    @Environment(\.dismiss) private var dismiss
    @State private var episodes: [Episode] = []
    @State private var selectedEpisode: Episode?
    @State private var isLoading = true
    @State private var message = ""

    private let columns = [GridItem(.adaptive(minimum: 54, maximum: 54), spacing: 27)]

    var body: some View {
        ZStack {
            FrostedBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Button("返回搜索结果") { dismiss() }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Theme.teal, in: RoundedRectangle(cornerRadius: 16))
                    Text(video.title)
                        .font(.system(size: 23))
                        .foregroundStyle(Theme.ink)
                    let subtitle = [video.year, video.remarks].filter { !$0.isEmpty }.joined(separator: " · ")
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.muted)
                    }
                    if isLoading {
                        ProgressView().tint(Theme.teal)
                    } else if !episodes.isEmpty {
                        Text("选择剧集（\(episodes.count)）")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.ink)
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 27) {
                            ForEach(episodes.indices, id: \.self) { index in
                                let episode = episodes[index]
                                Button { selectedEpisode = episode } label: {
                                    Text(String(format: "%02d", index + 1))
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(Theme.ink)
                                        .frame(width: 54, height: 54)
                                        .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 9))
                                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(.white.opacity(0.7)))
                                }
                                .accessibilityLabel(episode.name)
                            }
                        }
                    } else {
                        Text(message)
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.ink)
                    }
                }
                .padding(18)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $selectedEpisode) { episode in
            PlayerScreen(video: video, episode: episode)
        }
        .task {
            guard UsageWindow.isActive() else {
                isLoading = false
                message = "网络不可用"
                return
            }
            do {
                episodes = try await VideoAPI.episodes(for: video)
                message = episodes.isEmpty ? "此片源没有可直接播放的地址，请尝试其他影片。" : ""
            } catch {
                message = "加载失败，请检查网络或片源"
            }
            isLoading = false
        }
    }
}
