import SwiftUI

// ============================================================
// Root
// ============================================================
struct RootView: View {
    @ObservedObject var state = AppState.shared

    var body: some View {
        Group {
            if state.isJoined {
                ChatView()
            } else {
                JoinView()
            }
        }
        .preferredColorScheme(.dark)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0x0f1319).ignoresSafeArea())
    }
}

// ============================================================
// Join screen
// ============================================================
struct JoinView: View {
    @ObservedObject var state = AppState.shared
    @State private var name: String = ""
    @State private var avatarData: Data?
    @State private var showPicker = false
    @State private var isJoining = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x1b2838), Color(hex: 0x0e141c)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 60)

                    Text("Chattec")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: 0x66c0f4))

                    Text("Pick a name and photo to enter the chat")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x8f98a0))

                    Button {
                        showPicker = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: 0x66c0f4), Color(hex: 0x2a475e)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 110, height: 110)

                            if let d = avatarData, let ui = UIImage(data: d) {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(Circle())
                            } else {
                                Text("?")
                                    .font(.system(size: 44, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 12)

                    Text("Tap to upload a photo (optional)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: 0x8f98a0))

                    TextField("Your name", text: $name)
                        .padding(13)
                        .background(Color.black.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.top, 8)

                    Button {
                        joinTapped()
                    } label: {
                        Text(isJoining ? "Joining..." : "Enter Chat")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(13)
                            .background(LinearGradient(
                                colors: [Color(hex: 0x67c1f5), Color(hex: 0x417a9b)],
                                startPoint: .top, endPoint: .bottom))
                            .cornerRadius(6)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isJoining)
                    .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)

                    if let err = state.connectionError {
                        Text(err)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(8)
                    }

                    Spacer().frame(height: 80)
                }
                .padding(28)
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showPicker) {
            PhotoPicker { data in
                avatarData = data
                showPicker = false
            }
        }
        .onAppear {
            state.connectAnonymous()
        }
    }

    private func joinTapped() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isJoining = true

        var avatar: String? = nil
        if let d = avatarData {
            avatar = "data:image/jpeg;base64,\(d.base64EncodedString())"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            state.join(name: trimmed, avatar: avatar)
        }
    }
}

// ============================================================
// Chat screen
// ============================================================
struct ChatView: View {
    @ObservedObject var state = AppState.shared
    @State private var draft: String = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            messagesList
            if let t = state.typingName {
                typingRow(t)
            }
            inputBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Header
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Chattec")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text("\(state.onlineCount) online")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x57cbde))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0x16202d).ignoresSafeArea(edges: .top))
    }

    // MARK: Messages
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if state.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(state.messages) { m in
                            MessageRow(message: m, isMine: m.authorId == state.me?.id)
                                .id(m.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(hex: 0x0f1319))
            .onChange(of: state.messages.count) { _ in
                if let last = state.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 42))
                .foregroundColor(Color(hex: 0x2a475e))
            Text("No messages yet")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0x4a5f70))
            Text("Be the first to say something")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: 0x4a5f70))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: Typing
    private func typingRow(_ name: String) -> some View {
        Text("\(name) is typing...")
            .font(.system(size: 12))
            .italic()
            .foregroundColor(Color(hex: 0x8f98a0))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
            .background(Color(hex: 0x0f1319))
    }

    // MARK: Input
    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Message...", text: $draft, onCommit: sendDraft)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(22)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: draft) { newValue in
                    state.sendTyping(!newValue.isEmpty)
                }

            Button(action: sendDraft) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: 0x0f1319))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: 0x66c0f4))
                    .clipShape(Circle())
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: 0x16202d).ignoresSafeArea(edges: .bottom))
    }

    private func sendDraft() {
        let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        state.send(text: t)
        draft = ""
        state.sendTyping(false)
    }
}

// ============================================================
// Message row
// ============================================================
struct MessageRow: View {
    let message: Message
    let isMine: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if isMine { Spacer(minLength: 40) }

            if !isMine {
                AvatarView(initial: message.initial,
                           dataURL: message.avatar,
                           size: 38)
                .padding(.top, 18)
            }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(message.author)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(hex: 0x66c0f4))
                    Text(message.time)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: 0x8f98a0))
                }

                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isMine ? Color(hex: 0x1a9fff) : Color(hex: 0x2a3f5a))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if !isMine { Spacer(minLength: 40) }
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }
}

// ============================================================
// Avatar
// ============================================================
struct AvatarView: View {
    let initial: String
    let dataURL: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let decoded = decode(dataURL), let img = UIImage(data: decoded) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: 0x66c0f4), Color(hex: 0x2a475e)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                    Text(initial)
                        .font(.system(size: size * 0.42, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private func decode(_ s: String?) -> Data? {
        guard let s = s, let comma = s.firstIndex(of: ",") else { return nil }
        let b64 = String(s[s.index(after: comma)...])
        return Data(base64Encoded: b64)
    }
}

// ============================================================
// Photo picker
// ============================================================
struct PhotoPicker: UIViewControllerRepresentable {
    let onPick: (Data) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPick: (Data) -> Void
        init(onPick: @escaping (Data) -> Void) { self.onPick = onPick }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage,
               let data = img.jpegData(compressionQuality: 0.7) {
                onPick(data)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// ============================================================
// Color helper
// ============================================================
extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255.0,
            green: Double((hex >> 8) & 0xff) / 255.0,
            blue: Double(hex & 0xff) / 255.0,
            opacity: 1.0
        )
    }
}
