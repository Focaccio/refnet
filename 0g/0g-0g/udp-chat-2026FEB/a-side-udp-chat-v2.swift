import Cocoa
import Foundation
import Darwin

struct Config {
    var sideAIP: String
    var sideZIP: String
    var aToZSourcePort: UInt16
    var aToZDestPort: UInt16
    var zToASourcePort: UInt16
    var zToADestPort: UInt16
}

final class MessageTextView: NSTextView {
    var onEnterPressed: ((Bool) -> Void)?

    override func keyDown(with event: NSEvent) {
        let isEnter = event.keyCode == 36 || event.keyCode == 76
        if isEnter {
            let isShift = event.modifierFlags.contains(.shift)
            onEnterPressed?(isShift)
            if !isShift {
                return
            }
        }
        super.keyDown(with: event)
    }
}

final class UDPChatApp: NSObject, NSApplicationDelegate, NSWindowDelegate, NSTextViewDelegate {
    private let displayName = "Side A"
    private let sendLabel = "A->Z"
    private let recvLabel = "Z->A"
    private let probePayloadText = "AAAAA-AAAAA-AAAAA-AAAAA-AAAAA"
    private let remoteProbePayloadText = "ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ"
    private let maxInputLines = 3
    private let sendFromA = true
    private let historyBackgroundColor = NSColor(calibratedRed: 0.93, green: 0.96, blue: 0.99, alpha: 1.0)
    private let messageBackgroundColor = NSColor(calibratedRed: 0.95, green: 0.98, blue: 0.94, alpha: 1.0)

    private var config = Config(
        sideAIP: "0.0.0.0",
        sideZIP: "127.0.0.1",
        aToZSourcePort: 7000,
        aToZDestPort: 7000,
        zToASourcePort: 7001,
        zToADestPort: 7001
    )

    private var sendFD: Int32 = -1
    private var recvFD: Int32 = -1
    private var isTrimmingInput = false
    private var lastRxUtc = Date()
    private var lastAutoRecoverUtc = Date.distantPast

    private var probeTimer: Timer?
    private var receiveTimer: Timer?
    private var watchdogTimer: Timer?

    private var window: NSWindow!
    private var txtSideAIP: NSTextField!
    private var txtSideZIP: NSTextField!
    private var txtAToZSrc: NSTextField!
    private var txtAToZDst: NSTextField!
    private var txtZToASrc: NSTextField!
    private var txtZToADst: NSTextField!
    private var lblChannel1: NSTextField!
    private var lblChannel2: NSTextField!
    private var historyView: NSTextView!
    private var messageView: MessageTextView!
    private var statusLabel: NSTextField!

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyCommandLineArgs()
        buildUI()

        do {
            try initializeNetwork(next: config)
            addChatLine(prefix: "[System]", message: "Initialized as \(displayName).")
        } catch {
            addChatLine(prefix: "[Error]", message: "Startup failed: \(error.localizedDescription)")
        }

        startTimers()
        sendProbePacket()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func windowWillClose(_ notification: Notification) {
        shutdown()
    }

    func textDidChange(_ notification: Notification) {
        guard let tv = notification.object as? NSTextView, tv === messageView else { return }
        enforceMessageLineLimit()
    }

    private func applyCommandLineArgs() {
        let args = CommandLine.arguments
        if args.count > 1 { config.sideAIP = args[1] }
        if args.count > 2 { config.sideZIP = args[2] }
        if args.count > 3, let p = UInt16(args[3]) { config.aToZSourcePort = p }
        if args.count > 4, let p = UInt16(args[4]) { config.aToZDestPort = p }
        if args.count > 5, let p = UInt16(args[5]) { config.zToASourcePort = p }
        if args.count > 6, let p = UInt16(args[6]) { config.zToADestPort = p }
    }

    private func buildUI() {
        let rect = NSRect(x: 120, y: 120, width: 1080, height: 780)
        window = NSWindow(contentRect: rect,
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered,
                          defer: false)
        window.title = "UDP P2P Chat - \(displayName)"
        window.minSize = NSSize(width: 920, height: 640)
        window.delegate = self

        guard let content = window.contentView else { return }

        let titleLabel = makeLabel("Peer-to-Peer UDP Chat (\(displayName))", frame: NSRect(x: 14, y: 742, width: 1020, height: 24), bold: true)
        content.addSubview(titleLabel)

        content.addSubview(makeLabel("Side-A IP", frame: NSRect(x: 14, y: 708, width: 76, height: 24)))
        txtSideAIP = makeField(config.sideAIP, frame: NSRect(x: 92, y: 706, width: 150, height: 24))
        content.addSubview(txtSideAIP)

        content.addSubview(makeLabel("A->Z Src", frame: NSRect(x: 254, y: 708, width: 90, height: 24)))
        txtAToZSrc = makeField("\(config.aToZSourcePort)", frame: NSRect(x: 344, y: 706, width: 78, height: 24))
        content.addSubview(txtAToZSrc)

        content.addSubview(makeLabel("A->Z Dest", frame: NSRect(x: 434, y: 708, width: 90, height: 24)))
        txtAToZDst = makeField("\(config.aToZDestPort)", frame: NSRect(x: 524, y: 706, width: 78, height: 24))
        content.addSubview(txtAToZDst)

        content.addSubview(makeLabel("Side-Z IP", frame: NSRect(x: 14, y: 674, width: 76, height: 24)))
        txtSideZIP = makeField(config.sideZIP, frame: NSRect(x: 92, y: 672, width: 150, height: 24))
        content.addSubview(txtSideZIP)

        content.addSubview(makeLabel("Z->A Src", frame: NSRect(x: 254, y: 674, width: 90, height: 24)))
        txtZToASrc = makeField("\(config.zToASourcePort)", frame: NSRect(x: 344, y: 672, width: 78, height: 24))
        content.addSubview(txtZToASrc)

        content.addSubview(makeLabel("Z->A Dest", frame: NSRect(x: 434, y: 674, width: 90, height: 24)))
        txtZToADst = makeField("\(config.zToADestPort)", frame: NSRect(x: 524, y: 672, width: 78, height: 24))
        content.addSubview(txtZToADst)

        let applyBtn = NSButton(frame: NSRect(x: 900, y: 672, width: 134, height: 58))
        applyBtn.title = "Apply"
        applyBtn.font = NSFont.systemFont(ofSize: 13)
        applyBtn.target = self
        applyBtn.action = #selector(applyNetworkSettings)
        content.addSubview(applyBtn)

        lblChannel1 = makeLabel("", frame: NSRect(x: 14, y: 646, width: 1020, height: 22))
        lblChannel2 = makeLabel("", frame: NSRect(x: 14, y: 624, width: 1020, height: 22))
        content.addSubview(lblChannel1)
        content.addSubview(lblChannel2)

        let hint = makeLabel("Enter sends. Shift+Enter inserts newline. Message input is limited to 3 lines.", frame: NSRect(x: 14, y: 602, width: 1020, height: 22))
        content.addSubview(hint)

        let historyScroll = NSScrollView(frame: NSRect(x: 14, y: 190, width: 1020, height: 404))
        historyScroll.hasVerticalScroller = true
        historyScroll.autoresizingMask = [.width, .height]
        historyView = NSTextView(frame: historyScroll.bounds)
        historyView.isEditable = false
        historyView.font = NSFont.systemFont(ofSize: 12)
        historyView.isRichText = false
        historyView.drawsBackground = true
        historyView.backgroundColor = historyBackgroundColor
        historyView.textColor = .black
        historyView.textContainer?.widthTracksTextView = true
        historyScroll.documentView = historyView
        content.addSubview(historyScroll)

        let messageScroll = NSScrollView(frame: NSRect(x: 14, y: 100, width: 870, height: 80))
        messageScroll.hasVerticalScroller = true
        messageScroll.autoresizingMask = [.width, .minYMargin]
        messageView = MessageTextView(frame: messageScroll.bounds)
        messageView.font = NSFont.systemFont(ofSize: 13)
        messageView.isRichText = false
        messageView.isAutomaticQuoteSubstitutionEnabled = false
        messageView.isAutomaticDashSubstitutionEnabled = false
        messageView.drawsBackground = true
        messageView.backgroundColor = messageBackgroundColor
        messageView.textColor = .black
        messageView.insertionPointColor = .black
        messageView.delegate = self
        messageView.onEnterPressed = { [weak self] isShift in
            guard let self else { return }
            if isShift {
                if self.currentMessageLineCount() >= self.maxInputLines {
                    NSSound.beep()
                }
                return
            }
            self.sendMessage()
        }
        messageScroll.documentView = messageView
        content.addSubview(messageScroll)

        let sendBtn = NSButton(frame: NSRect(x: 900, y: 100, width: 134, height: 80))
        sendBtn.title = "Send"
        sendBtn.font = NSFont.systemFont(ofSize: 14)
        sendBtn.target = self
        sendBtn.action = #selector(sendMessageButton)
        content.addSubview(sendBtn)

        statusLabel = makeLabel("Starting...", frame: NSRect(x: 14, y: 16, width: 1020, height: 20))
        statusLabel.textColor = .secondaryLabelColor
        content.addSubview(statusLabel)

        let anchors: [NSView] = [titleLabel, txtSideAIP, txtAToZSrc, txtAToZDst, txtSideZIP, txtZToASrc, txtZToADst, applyBtn, lblChannel1, lblChannel2, hint, historyScroll, messageScroll, sendBtn, statusLabel]
        for view in anchors {
            if view === historyScroll || view === messageScroll || view === statusLabel || view === applyBtn || view === sendBtn {
                continue
            }
            view.autoresizingMask = [.maxXMargin, .minYMargin]
        }
        applyBtn.autoresizingMask = [.minXMargin, .minYMargin]
        sendBtn.autoresizingMask = [.minXMargin, .maxYMargin]

        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(messageView)
    }

    private func makeLabel(_ text: String, frame: NSRect, bold: Bool = false) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.frame = frame
        label.font = bold ? NSFont.boldSystemFont(ofSize: 14) : NSFont.systemFont(ofSize: 12)
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    private func makeField(_ text: String, frame: NSRect) -> NSTextField {
        let field = NSTextField(frame: frame)
        field.stringValue = text
        field.font = NSFont.systemFont(ofSize: 12)
        return field
    }

    private func startTimers() {
        probeTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.sendProbePacket()
        }

        receiveTimer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: true) { [weak self] _ in
            self?.drainReceiveSocket()
        }

        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            self?.watchdogTick()
        }
    }

    private func addChatLine(prefix: String, message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let line = "[\(formatter.string(from: Date()))] \(prefix) \(message)"

        let needsLeadingNewline = !historyView.string.isEmpty
        if needsLeadingNewline {
            historyView.textStorage?.append(NSAttributedString(string: "\n" + line))
        } else {
            historyView.textStorage?.append(NSAttributedString(string: line))
        }
        historyView.scrollToEndOfDocument(nil)
    }

    private func currentMessageLineCount() -> Int {
        let text = messageView.string
        if text.isEmpty { return 1 }
        return text.split(whereSeparator: \ .isNewline).count + (text.hasSuffix("\n") ? 1 : 0)
    }

    private func enforceMessageLineLimit() {
        if isTrimmingInput { return }
        let lines = messageView.string.components(separatedBy: CharacterSet.newlines)
        if lines.count > maxInputLines {
            isTrimmingInput = true
            messageView.string = lines.prefix(maxInputLines).joined(separator: "\n")
            messageView.setSelectedRange(NSRange(location: messageView.string.count, length: 0))
            isTrimmingInput = false
        }
    }

    private func parsePort(_ text: String, fieldName: String) throws -> UInt16 {
        guard let value = Int(text), value >= 1, value <= 65535 else {
            throw NSError(domain: "udp-chat", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(fieldName) must be between 1 and 65535."])
        }
        return UInt16(value)
    }

    private func updateNetworkLabels() {
        lblChannel1.stringValue = "Channel A -> Z : side-a \(config.sideAIP):\(config.aToZSourcePort) -> side-z \(config.sideZIP):\(config.aToZDestPort)"
        lblChannel2.stringValue = "Channel Z -> A : side-z \(config.sideZIP):\(config.zToASourcePort) -> side-a \(config.sideAIP):\(config.zToADestPort)"
        statusLabel.stringValue = "Send(A->Z): \(config.sideAIP):\(config.aToZSourcePort) -> \(config.sideZIP):\(config.aToZDestPort) | Recv(Z->A): \(config.sideAIP):\(config.zToADestPort)"
    }

    private func closeSockets() {
        if sendFD >= 0 {
            _ = Darwin.close(sendFD)
            sendFD = -1
        }
        if recvFD >= 0 {
            _ = Darwin.close(recvFD)
            recvFD = -1
        }
    }

    private func setNonBlocking(_ fd: Int32) {
        let flags = fcntl(fd, F_GETFL, 0)
        _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)
    }

    private func makeBoundSocket(ip: String, port: UInt16, nonBlocking: Bool) throws -> Int32 {
        let fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard fd >= 0 else { throw socketError("socket() failed") }

        var on: Int32 = 1
        if setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int32>.size)) != 0 {
            _ = Darwin.close(fd)
            throw socketError("setsockopt(SO_REUSEADDR) failed")
        }

        if nonBlocking { setNonBlocking(fd) }

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian

        if ip == "0.0.0.0" {
            addr.sin_addr = in_addr(s_addr: INADDR_ANY.bigEndian)
        } else {
            let rc = ip.withCString { inet_pton(AF_INET, $0, &addr.sin_addr) }
            if rc != 1 {
                _ = Darwin.close(fd)
                throw NSError(domain: "udp-chat", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid IPv4 address: \(ip)"])
            }
        }

        var bindAddr = addr
        let bindResult = withUnsafePointer(to: &bindAddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        if bindResult != 0 {
            _ = Darwin.close(fd)
            throw socketError("bind(\(ip):\(port)) failed")
        }

        return fd
    }

    private func initializeNetwork(next: Config) throws {
        let sendLocalIP = sendFromA ? next.sideAIP : next.sideZIP
        let sendLocalPort = sendFromA ? next.aToZSourcePort : next.zToASourcePort
        let recvLocalIP = sendFromA ? next.sideAIP : next.sideZIP
        let recvLocalPort = sendFromA ? next.zToADestPort : next.aToZDestPort

        let nextSend = try makeBoundSocket(ip: sendLocalIP, port: sendLocalPort, nonBlocking: false)
        let nextRecv = try makeBoundSocket(ip: recvLocalIP, port: recvLocalPort, nonBlocking: true)

        closeSockets()
        sendFD = nextSend
        recvFD = nextRecv
        config = next
        updateNetworkLabels()
    }

    private func testExpectedPeer(ip: String, port: UInt16, expectedIP: String, expectedPort: UInt16) -> Bool {
        if port != expectedPort { return false }
        if expectedIP == "0.0.0.0" || expectedIP == "::" { return true }
        return ip == expectedIP
    }

    private func endpointIPString(_ addr: in_addr) -> String {
        var mutableAddr = addr
        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        let result = withUnsafePointer(to: &mutableAddr) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<in_addr>.size) {
                inet_ntop(AF_INET, $0, &buffer, socklen_t(INET_ADDRSTRLEN))
            }
        }
        if result == nil { return "unknown" }
        return String(cString: buffer)
    }

    private func drainReceiveSocket() {
        guard recvFD >= 0 else { return }

        while true {
            var peer = sockaddr_in()
            var peerLen: socklen_t = socklen_t(MemoryLayout<sockaddr_in>.size)
            var buffer = [UInt8](repeating: 0, count: 65535)

            let count = withUnsafeMutablePointer(to: &peer) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    recvfrom(recvFD, &buffer, buffer.count, 0, $0, &peerLen)
                }
            }

            if count < 0 {
                if errno == EAGAIN || errno == EWOULDBLOCK {
                    break
                }
                addChatLine(prefix: "[Error]", message: "Receive failed: \(String(cString: strerror(errno)))")
                break
            }

            let data = Data(buffer[0..<Int(count)])
            let msg = String(data: data, encoding: .utf8) ?? "<non-UTF8 \(count) bytes>"
            let endpointIP = endpointIPString(peer.sin_addr)
            let endpointPort = UInt16(bigEndian: peer.sin_port)
            let endpointText = "\(endpointIP):\(endpointPort)"
            lastRxUtc = Date()

            let expectedIP = sendFromA ? config.sideZIP : config.sideAIP
            let expectedPort = sendFromA ? config.zToASourcePort : config.aToZSourcePort
            let isExpected = testExpectedPeer(ip: endpointIP, port: endpointPort, expectedIP: expectedIP, expectedPort: expectedPort)

            if msg == remoteProbePayloadText {
                if isExpected {
                    addChatLine(prefix: "[Probe RX \(endpointText) \(recvLabel)]", message: msg)
                } else {
                    addChatLine(prefix: "[Probe RX Unverified \(endpointText) \(recvLabel)]", message: msg)
                }
            } else {
                if isExpected {
                    addChatLine(prefix: "[\(endpointText) \(recvLabel)]", message: msg)
                } else {
                    addChatLine(prefix: "[Unverified \(endpointText) \(recvLabel)]", message: msg)
                }
            }
        }
    }

    @objc private func applyNetworkSettings() {
        do {
            let nextSideAIP = txtSideAIP.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let nextSideZIP = txtSideZIP.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if nextSideAIP.isEmpty { throw NSError(domain: "udp-chat", code: 3, userInfo: [NSLocalizedDescriptionKey: "Side-A IP is required."]) }
            if nextSideZIP.isEmpty { throw NSError(domain: "udp-chat", code: 3, userInfo: [NSLocalizedDescriptionKey: "Side-Z IP is required."]) }

            let next = try Config(
                sideAIP: nextSideAIP,
                sideZIP: nextSideZIP,
                aToZSourcePort: parsePort(txtAToZSrc.stringValue.trimmingCharacters(in: .whitespacesAndNewlines), fieldName: "A->Z Source Port"),
                aToZDestPort: parsePort(txtAToZDst.stringValue.trimmingCharacters(in: .whitespacesAndNewlines), fieldName: "A->Z Destination Port"),
                zToASourcePort: parsePort(txtZToASrc.stringValue.trimmingCharacters(in: .whitespacesAndNewlines), fieldName: "Z->A Source Port"),
                zToADestPort: parsePort(txtZToADst.stringValue.trimmingCharacters(in: .whitespacesAndNewlines), fieldName: "Z->A Destination Port")
            )

            try initializeNetwork(next: next)
            addChatLine(prefix: "[System]", message: "Network settings applied.")
        } catch {
            addChatLine(prefix: "[Error]", message: "Apply failed: \(error.localizedDescription)")
        }
    }

    @objc private func sendMessageButton() {
        sendMessage()
    }

    private func sendMessage() {
        let text = messageView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return }

        do {
            try sendPayload(Array(text.utf8))
            addChatLine(prefix: "[\(displayName) \(sendLabel)]", message: text)
            messageView.string = ""
            window.makeFirstResponder(messageView)
        } catch {
            addChatLine(prefix: "[Error]", message: "Send failed: \(error.localizedDescription)")
        }
    }

    private func sendProbePacket() {
        do {
            try sendPayload(Array(probePayloadText.utf8))
            addChatLine(prefix: "[Probe TX]", message: probePayloadText)
        } catch {
            addChatLine(prefix: "[Error]", message: "Probe send failed: \(error.localizedDescription)")
        }
    }

    private func sendPayload(_ payload: [UInt8]) throws {
        guard sendFD >= 0 else {
            throw NSError(domain: "udp-chat", code: 5, userInfo: [NSLocalizedDescriptionKey: "Network is not initialized."])
        }

        let remoteIP = sendFromA ? config.sideZIP : config.sideAIP
        let remotePort = sendFromA ? config.aToZDestPort : config.zToADestPort

        var remote = sockaddr_in()
        remote.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        remote.sin_family = sa_family_t(AF_INET)
        remote.sin_port = remotePort.bigEndian

        let rc = remoteIP.withCString { inet_pton(AF_INET, $0, &remote.sin_addr) }
        if rc != 1 {
            throw NSError(domain: "udp-chat", code: 6, userInfo: [NSLocalizedDescriptionKey: "Invalid destination IPv4 address: \(remoteIP)"])
        }

        let sent = payload.withUnsafeBytes { ptr in
            withUnsafePointer(to: &remote) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    sendto(sendFD, ptr.baseAddress, payload.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }

        if sent != payload.count {
            throw socketError("sendto() failed")
        }
    }

    private func watchdogTick() {
        guard sendFD >= 0, recvFD >= 0 else { return }

        let now = Date()
        let secondsSinceRx = now.timeIntervalSince(lastRxUtc)
        let secondsSinceRecover = now.timeIntervalSince(lastAutoRecoverUtc)

        if secondsSinceRx >= 45 && secondsSinceRecover >= 45 {
            lastAutoRecoverUtc = now
            addChatLine(prefix: "[System]", message: "No inbound traffic for \(Int(secondsSinceRx))s; auto-reinitializing UDP sockets.")
            do {
                try initializeNetwork(next: config)
                sendProbePacket()
            } catch {
                addChatLine(prefix: "[Error]", message: "Auto-recover failed: \(error.localizedDescription)")
            }
        }
    }

    private func socketError(_ label: String) -> NSError {
        NSError(domain: "udp-chat", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "\(label): \(String(cString: strerror(errno)))"])
    }

    private func shutdown() {
        probeTimer?.invalidate()
        receiveTimer?.invalidate()
        watchdogTimer?.invalidate()
        closeSockets()
    }
}

let app = NSApplication.shared
let delegate = UDPChatApp()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
