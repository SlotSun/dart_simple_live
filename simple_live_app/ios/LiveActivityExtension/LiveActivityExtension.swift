import ActivityKit
import SwiftUI
import WidgetKit

struct LiveStreamActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var online: Int
        var isLive: Bool
    }

    var title: String
    var artist: String
    var thumbnailUrl: String
    var isLive: Bool
}

struct LiveBadge: View {
    let isLive: Bool
    let online: Int

    var body: some View {
        if isLive {
            HStack(spacing: 4) {
                Circle().fill(.red).frame(width: 8, height: 8)
                Text("LIVE").font(.caption2).fontWeight(.bold)
                Text("\(online)").font(.caption2).monospacedDigit()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.red.opacity(0.16))
            .clipShape(Capsule())
        } else {
            Text("已结束").font(.caption2).foregroundStyle(.secondary)
        }
    }
}

struct LiveActivityExtensionView: View {
    let context: ActivityViewContext<LiveStreamActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: context.attributes.thumbnailUrl)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(context.attributes.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            LiveBadge(isLive: context.state.isLive, online: context.state.online)
        }
        .padding()
    }
}

@main
struct LiveActivityExtensionBundle: WidgetBundle {
    var body: some Widget {
        LiveActivityWidget()
    }
}

struct LiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveStreamActivityAttributes.self) { context in
            LiveActivityExtensionView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    AsyncImage(url: URL(string: context.attributes.thumbnailUrl)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(context.attributes.artist)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    LiveBadge(isLive: context.state.isLive, online: context.state.online)
                }
            } compactLeading: {
                AsyncImage(url: URL(string: context.attributes.thumbnailUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } compactTrailing: {
                if context.state.isLive {
                    HStack(spacing: 3) {
                        Circle().fill(.red).frame(width: 6, height: 6)
                        Text("LIVE").font(.caption2).fontWeight(.bold)
                    }
                } else {
                    Image(systemName: "checkmark")
                }
            } minimal: {
                AsyncImage(url: URL(string: context.attributes.thumbnailUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())
            }
        }
    }
}
