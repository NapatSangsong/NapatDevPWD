import SwiftUI

struct ChatView: View {
    @Environment(VaultStore.self) private var store
    @Environment(AssistantSettings.self) private var assistantSettings
    @State private var viewModel: AssistantViewModel?
    @FocusState private var inputFocused: Bool

    var body: some View {
        Group {
            if let vm = viewModel {
                bodyWith(vm)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = AssistantViewModel(store: store, settings: assistantSettings)
            }
        }
    }

    @ViewBuilder
    private func bodyWith(_ vm: AssistantViewModel) -> some View {
        VStack(spacing: 0) {
            header(vm)
            Divider().background(DesignTokens.hairline)
            if !vm.isConfigured {
                missingKeyNotice
            }
            transcript(vm)
            Divider().background(DesignTokens.hairline)
            composer(vm)
        }
        .background(DesignTokens.bg)
    }

    private func header(_ vm: AssistantViewModel) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x5B7CFA), Color(hex: 0x8AA1FF)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 26, height: 26)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                )
            VStack(alignment: .leading, spacing: 1) {
                Text("Assistant")
                    .font(.nd(14, weight: .bold))
                    .foregroundStyle(DesignTokens.ink)
                Text("Claude Haiku · edits require approval")
                    .font(.nd(10.5))
                    .foregroundStyle(DesignTokens.muted)
            }
            Spacer()
            if let usage = vm.usageSummary {
                Text(usage)
                    .font(.ndMono(10))
                    .foregroundStyle(DesignTokens.muted2)
            }
            Button { vm.reset() } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignTokens.muted)
            }
            .buttonStyle(.plain)
            .disabled(vm.turns.isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var missingKeyNotice: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("No API key configured", systemImage: "exclamationmark.triangle.fill")
                .font(.nd(12, weight: .semibold))
                .foregroundStyle(Color(hex: 0xF5A524))
            Text("Copy `Secrets.plist.example` to `Secrets.plist`, paste your Anthropic key, rebuild.")
                .font(.nd(11.5))
                .foregroundStyle(DesignTokens.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: 0xF5A524).opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 14)
        .padding(.top, 10)
    }

    private func transcript(_ vm: AssistantViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if vm.turns.isEmpty {
                        empty
                    } else {
                        ForEach(vm.turns) { turn in
                            turnRow(turn, vm: vm)
                                .id(turn.id)
                        }
                    }
                    if vm.isThinking { thinkingIndicator }
                }
                .padding(14)
            }
            .onChange(of: vm.turns.count) { _, _ in
                if let last = vm.turns.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundStyle(DesignTokens.accent)
            Text("Ask the assistant to update a password, look up a login, or generate a new one.")
                .font(.nd(12.5))
                .foregroundStyle(DesignTokens.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private func turnRow(_ turn: ChatTurn, vm: AssistantViewModel) -> some View {
        if let proposalID = turn.proposalID, let proposal = vm.proposals[proposalID] {
            ProposalCard(
                proposal: proposal,
                onApply: { vm.apply(proposal: proposalID) },
                onCancel: { vm.cancel(proposal: proposalID) }
            )
        } else {
            messageBubble(turn)
        }
    }

    private func messageBubble(_ turn: ChatTurn) -> some View {
        HStack {
            if turn.role == .user { Spacer(minLength: 40) }
            Text(turn.text)
                .font(.nd(13))
                .foregroundStyle(turn.role == .user ? .white : (turn.isError ? Color(hex: 0xE11D48) : DesignTokens.ink))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(bubbleBackground(for: turn))
                .textSelection(.enabled)
            if turn.role != .user { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder
    private func bubbleBackground(for turn: ChatTurn) -> some View {
        switch turn.role {
        case .user:
            LinearGradient(colors: [Color(hex: 0x6D8BFC), Color(hex: 0x4E6DF0)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        case .assistant:
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(DesignTokens.cardSolid)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(DesignTokens.hairline, lineWidth: 0.5)
                )
        case .system:
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill((turn.isError ? Color(hex: 0xE11D48) : DesignTokens.muted).opacity(0.1))
        }
    }

    private var thinkingIndicator: some View {
        HStack(spacing: 6) {
            ProgressView().controlSize(.small)
            Text("Thinking…").font(.nd(12)).foregroundStyle(DesignTokens.muted)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(DesignTokens.cardSolid, in: RoundedRectangle(cornerRadius: 10))
    }

    private func composer(_ vm: AssistantViewModel) -> some View {
        HStack(spacing: 8) {
            TextField("Ask the assistant…", text: Binding(
                get: { vm.input },
                set: { vm.input = $0 }
            ), axis: .vertical)
                .textFieldStyle(.plain)
                .font(.nd(13))
                .lineLimit(1...4)
                .focused($inputFocused)
                .onSubmit { vm.send() }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DesignTokens.cardSolid, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(DesignTokens.hairline, lineWidth: 0.5)
                )
                #if canImport(UIKit)
                .textInputAutocapitalization(.sentences)
                #endif

            if vm.isThinking {
                Button { vm.stop() } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: 0xE11D48), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Stop")
            } else {
                Button { vm.send() } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            LinearGradient(colors: [Color(hex: 0x6D8BFC), Color(hex: 0x4E6DF0)], startPoint: .top, endPoint: .bottom),
                            in: Circle()
                        )
                }
                .buttonStyle(.plain)
                .disabled(vm.input.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(vm.input.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
