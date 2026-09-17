import Foundation
import SocketIO
import SwiftUI
import Combine

// ============================================================
// Models
// ============================================================
struct Member: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let initial: String
    let avatar: String?

    enum CodingKeys: String, CodingKey {
        case id, name, initial, avatar
    }
}

struct Message: Codable, Identifiable, Equatable {
    let id: String
    let authorId: String
    let author: String
    let initial: String
    let avatar: String?
    let text: String
    let type: String
    let src: String?
    let fileName: String?
    let size: String?
    let time: String
    let ts: Double
}

// ============================================================
// AppState — holds everything and talks to the server
// ============================================================
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var me: Member?
    @Published var token: String?
    @Published var messages: [Message] = []
    @Published var onlineCount: Int = 0
    @Published var isJoined: Bool = false
    @Published var typingName: String?
    @Published var connectionError: String?

    private var manager: SocketManager?
    private var socket: SocketIOClient?

    let serverURL = URL(string: "https://subhyaloid-kallie-bihourly.ngrok-free.dev")!

    private init() {}

    // MARK: - Connect without token (for join)
    func connectAnonymous() {
        socket?.disconnect()
        socket?.removeAllHandlers()

        let cfg: SocketIOClientConfiguration = [
            .log(false),
            .compress,
            .reconnects(true),
            .reconnectAttempts(-1),
            .reconnectWait(2),
            .extraHeaders(["ngrok-skip-browser-warning": "true"]),
            .forceWebsockets(true)
        ]
        manager = SocketManager(socketURL: serverURL, config: cfg)
        socket = manager?.defaultSocket
        bind()
        socket?.connect()
    }

    // MARK: - Reconnect with token (authenticated)
    func connectWithToken(_ token: String) {
        socket?.disconnect()
        socket?.removeAllHandlers()

        let cfg: SocketIOClientConfiguration = [
            .log(false),
            .compress,
            .reconnects(true),
            .reconnectAttempts(-1),
            .reconnectWait(2),
            .extraHeaders(["ngrok-skip-browser-warning": "true"]),
            .connectParams(["token": token]),
            .forceWebsockets(true)
        ]
        manager = SocketManager(socketURL: serverURL, config: cfg)
        socket = manager?.defaultSocket
        bind()
        socket?.connect()
    }

    // MARK: - Actions
    func join(name: String, avatar: String?) {
        var payload: [String: Any] = ["name": name]
        if let a = avatar { payload["avatar"] = a }
        socket?.emit("room:join", payload)
    }

    func send(text: String) {
        socket?.emit("room:send", ["text": text, "type": "text"])
    }

    func sendTyping(_ typing: Bool) {
        socket?.emit("room:typing", ["typing": typing])
    }

    // MARK: - Socket bindings
    private func bind() {
        guard let socket = socket else { return }

        socket.on(clientEvent: .connect) { _, _ in
            print("✅ socket connected, sid =", self.socket?.sid ?? "-")
        }

        socket.on(clientEvent: .disconnect) { data, _ in
            print("❌ socket disconnected:", data)
        }

        socket.on(clientEvent: .error) { data, _ in
            print("⚠️ socket error:", data)
            DispatchQueue.main.async {
                self.connectionError = "Connection error"
            }
        }

        // --- Join OK ---
        socket.on("room:join:ok") { [weak self] data, _ in
            guard let self = self,
                  let dict = data.first as? [String: Any] else { return }

            if let userDict = dict["user"] as? [String: Any],
               let json = try? JSONSerialization.data(withJSONObject: userDict),
               let m = try? JSONDecoder().decode(Member.self, from: json) {
                DispatchQueue.main.async {
                    self.me = m
                    self.isJoined = true
                }
            }

            if let t = dict["token"] as? String {
                DispatchQueue.main.async {
                    self.token = t
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.connectWithToken(t)
                }
            }
        }

        // --- Join error ---
        socket.on("room:join:error") { [weak self] data, _ in
            guard let self = self,
                  let dict = data.first as? [String: Any],
                  let err = dict["error"] as? String else { return }
            DispatchQueue.main.async {
                self.connectionError = err
            }
        }

        // --- Self ---
        socket.on("room:self") { [weak self] data, _ in
            guard let self = self,
                  let dict = data.first as? [String: Any],
                  let json = try? JSONSerialization.data(withJSONObject: dict),
                  let m = try? JSONDecoder().decode(Member.self, from: json) else { return }
            DispatchQueue.main.async {
                self.me = m
            }
        }

        // --- Message ---
        socket.on("room:message") { [weak self] data, _ in
            guard let self = self,
                  let dict = data.first as? [String: Any],
                  let json = try? JSONSerialization.data(withJSONObject: dict),
                  let m = try? JSONDecoder().decode(Message.self, from: json) else { return }
            DispatchQueue.main.async {
                self.messages.append(m)
            }
        }

        // --- History ---
        socket.on("room:history") { [weak self] data, _ in
            guard let self = self,
                  let arr = data.first as? [[String: Any]] else { return }
            let msgs: [Message] = arr.compactMap { dict in
                guard let json = try? JSONSerialization.data(withJSONObject: dict),
                      let m = try? JSONDecoder().decode(Message.self, from: json) else { return nil }
                return m
            }
            DispatchQueue.main.async {
                self.messages = msgs
            }
        }

        // --- Members count ---
        socket.on("room:members") { [weak self] data, _ in
            guard let self = self,
                  let arr = data.first as? [[String: Any]] else { return }
            DispatchQueue.main.async {
                self.onlineCount = arr.count
            }
        }

        // --- Typing ---
        socket.on("room:typing") { [weak self] data, _ in
            guard let self = self,
                  let dict = data.first as? [String: Any],
                  let name = dict["name"] as? String,
                  let typing = dict["typing"] as? Bool else { return }
            DispatchQueue.main.async {
                self.typingName = typing ? name : nil
            }
        }

        // --- Message deleted ---
        socket.on("room:deleted") { [weak self] data, _ in
            guard let self = self,
                  let dict = data.first as? [String: Any],
                  let mid = dict["messageId"] as? String else { return }
            DispatchQueue.main.async {
                self.messages.removeAll { $0.id == mid }
            }
        }
    }
}
