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

final class UDPChatNode {
    private let displayName: String
    private let sendLabel: String
    private let recvLabel: String
    private let probePayloadText: String
    private let remoteProbePayloadText: String
    private let sendFromA: Bool

    private let lock = NSLock()
    private var config: Config
    private var sendFD: Int32 = -1
    private var recvFD: Int32 = -1
    private var running = true
    private var lastRxUtc = Date()
    private var lastAutoRecoverUtc = Date.distantPast

    init(displayName: String,
         sendLabel: String,
         recvLabel: String,
         probePayloadText: String,
         remoteProbePayloadText: String,
         sendFromA: Bool,
         initialConfig: Config) {
        self.displayName = displayName
        self.sendLabel = sendLabel
        self.recvLabel = recvLabel
        self.probePayloadText = probePayloadText
        self.remoteProbePayloadText = remoteProbePayloadText
        self.sendFromA = sendFromA
        self.config = initialConfig
    }

    func run() {
        do {
            try initializeNetwork(next: config)
            addChatLine(prefix: "[System]", message: "Initialized as \(displayName).")
        } catch {
            addChatLine(prefix: "[Error]", message: "Startup failed: \(error)")
            return
        }

        startReceiveLoop()
        startProbeLoop()
        startWatchdogLoop()
        printUsage()
        sendProbePacket()

        while running, let raw = readLine(strippingNewline: false) {
            let line = raw.trimmingCharacters(in: .newlines)
            if line.isEmpty { continue }

            if line == "/quit" || line == "/exit" {
                shutdown()
                break
            }

            if line == "/show" {
                showNetworkLabels()
                continue
            }

            if line.hasPrefix("/apply ") {
                applyFromCommand(line)
                continue
            }

            sendMessage(line)
        }

        shutdown()
    }

    private func printUsage() {
        print("\\nCommands:")
        print("  /show")
        print("  /apply <sideAIP> <sideZIP> <a2zSrc> <a2zDst> <z2aSrc> <z2aDst>")
        print("  /quit")
        print("Any other line is sent as a chat message.\\n")
    }

    private func addChatLine(prefix: String, message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        print("[\(timestamp)] \(prefix) \(message)")
    }

    private func showNetworkLabels() {
        lock.lock()
        let c = config
        lock.unlock()

        addChatLine(prefix: "[System]", message: "Channel A -> Z : side-a \(c.sideAIP):\(c.aToZSourcePort) -> side-z \(c.sideZIP):\(c.aToZDestPort)")
        addChatLine(prefix: "[System]", message: "Channel Z -> A : side-z \(c.sideZIP):\(c.zToASourcePort) -> side-a \(c.sideAIP):\(c.zToADestPort)")

        if sendFromA {
            addChatLine(prefix: "[System]", message: "Send(A->Z): \(c.sideAIP):\(c.aToZSourcePort) -> \(c.sideZIP):\(c.aToZDestPort) | Recv(Z->A): \(c.sideAIP):\(c.zToADestPort)")
        } else {
            addChatLine(prefix: "[System]", message: "Send(Z->A): \(c.sideZIP):\(c.zToASourcePort) -> \(c.sideAIP):\(c.zToADestPort) | Recv(A->Z): \(c.sideZIP):\(c.aToZDestPort)")
        }
    }

    private func parsePort(_ value: String, field: String) throws -> UInt16 {
        guard let intVal = Int(value), intVal >= 1, intVal <= 65535 else {
            throw NSError(domain: "udp-chat", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(field) must be between 1 and 65535."])
        }
        return UInt16(intVal)
    }

    private func applyFromCommand(_ line: String) {
        let parts = line.split(separator: " ").map(String.init)
        guard parts.count == 7 else {
            addChatLine(prefix: "[Error]", message: "Usage: /apply <sideAIP> <sideZIP> <a2zSrc> <a2zDst> <z2aSrc> <z2aDst>")
            return
        }

        do {
            let next = try Config(
                sideAIP: parts[1],
                sideZIP: parts[2],
                aToZSourcePort: parsePort(parts[3], field: "A->Z Source Port"),
                aToZDestPort: parsePort(parts[4], field: "A->Z Destination Port"),
                zToASourcePort: parsePort(parts[5], field: "Z->A Source Port"),
                zToADestPort: parsePort(parts[6], field: "Z->A Destination Port")
            )
            try initializeNetwork(next: next)
            addChatLine(prefix: "[System]", message: "Network settings applied.")
        } catch {
            addChatLine(prefix: "[Error]", message: "Apply failed: \(error.localizedDescription)")
        }
    }

    private func initializeNetwork(next: Config) throws {
        let sendLocalIP = sendFromA ? next.sideAIP : next.sideZIP
        let sendLocalPort = sendFromA ? next.aToZSourcePort : next.zToASourcePort
        let recvLocalIP = sendFromA ? next.sideAIP : next.sideZIP
        let recvLocalPort = sendFromA ? next.zToADestPort : next.aToZDestPort

        let nextSendFD = try makeBoundSocket(ip: sendLocalIP, port: sendLocalPort, receiveTimeoutMs: nil)
        let nextRecvFD = try makeBoundSocket(ip: recvLocalIP, port: recvLocalPort, receiveTimeoutMs: 200)

        lock.lock()
        closeIfOpen(sendFD)
        closeIfOpen(recvFD)
        sendFD = nextSendFD
        recvFD = nextRecvFD
        config = next
        lock.unlock()

        showNetworkLabels()
    }

    private func makeBoundSocket(ip: String, port: UInt16, receiveTimeoutMs: Int?) throws -> Int32 {
        let fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard fd >= 0 else { throw socketError("socket() failed") }

        var on: Int32 = 1
        if setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &on, socklen_t(MemoryLayout<Int32>.size)) != 0 {
            close(fd)
            throw socketError("setsockopt(SO_REUSEADDR) failed")
        }

        if let receiveTimeoutMs {
            var timeout = timeval(tv_sec: __darwin_time_t(receiveTimeoutMs / 1000), tv_usec: __darwin_suseconds_t((receiveTimeoutMs % 1000) * 1000))
            if setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size)) != 0 {
                close(fd)
                throw socketError("setsockopt(SO_RCVTIMEO) failed")
            }
        }

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian

        if ip == "0.0.0.0" {
            addr.sin_addr = in_addr(s_addr: INADDR_ANY.bigEndian)
        } else {
            let rc = ip.withCString { inet_pton(AF_INET, $0, &addr.sin_addr) }
            if rc != 1 {
                close(fd)
                throw NSError(domain: "udp-chat", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid IPv4 address: \(ip)"])
            }
        }

        var bindAddr = addr
        let bindResult = withUnsafePointer(to: &bindAddr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        if bindResult != 0 {
            close(fd)
            throw socketError("bind(\(ip):\(port)) failed")
        }

        return fd
    }

    private func startReceiveLoop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.receiveLoop()
        }
    }

    private func receiveLoop() {
        while running {
            lock.lock()
            let fd = recvFD
            let current = config
            lock.unlock()

            if fd < 0 {
                usleep(100_000)
                continue
            }

            var peer = sockaddr_in()
            var peerLen: socklen_t = socklen_t(MemoryLayout<sockaddr_in>.size)
            var buffer = [UInt8](repeating: 0, count: 65535)
            let count = withUnsafeMutablePointer(to: &peer) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    recvfrom(fd, &buffer, buffer.count, 0, $0, &peerLen)
                }
            }

            if count < 0 {
                let err = errno
                if err == EAGAIN || err == EWOULDBLOCK {
                    continue
                }
                addChatLine(prefix: "[Error]", message: "Receive failed: \(String(cString: strerror(err)))")
                usleep(200_000)
                continue
            }

            let data = Data(buffer[0..<Int(count)])
            let message = String(data: data, encoding: .utf8) ?? "<non-UTF8 \(count) bytes>"

            let endpointIP = endpointIPString(peer.sin_addr)
            let endpointPort = UInt16(bigEndian: peer.sin_port)
            let endpointText = "\(endpointIP):\(endpointPort)"

            lock.lock()
            lastRxUtc = Date()
            lock.unlock()

            let expectedIP = sendFromA ? current.sideZIP : current.sideAIP
            let expectedPort = sendFromA ? current.zToASourcePort : current.aToZSourcePort
            let isExpected = testExpectedPeer(ip: endpointIP, port: endpointPort, expectedIP: expectedIP, expectedPort: expectedPort)

            if message == remoteProbePayloadText {
                if isExpected {
                    addChatLine(prefix: "[Probe RX \(endpointText) \(recvLabel)]", message: message)
                } else {
                    addChatLine(prefix: "[Probe RX Unverified \(endpointText) \(recvLabel)]", message: message)
                }
            } else {
                if isExpected {
                    addChatLine(prefix: "[\(endpointText) \(recvLabel)]", message: message)
                } else {
                    addChatLine(prefix: "[Unverified \(endpointText) \(recvLabel)]", message: message)
                }
            }
        }
    }

    private func testExpectedPeer(ip: String, port: UInt16, expectedIP: String, expectedPort: UInt16) -> Bool {
        guard port == expectedPort else { return false }
        if expectedIP == "0.0.0.0" || expectedIP == "::" { return true }
        return ip == expectedIP
    }

    private func startProbeLoop() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            while self.running {
                Thread.sleep(forTimeInterval: 10)
                if !self.running { break }
                self.sendProbePacket()
            }
        }
    }

    private func startWatchdogLoop() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            while self.running {
                Thread.sleep(forTimeInterval: 15)
                if !self.running { break }

                self.lock.lock()
                let current = self.config
                let hasSockets = self.sendFD >= 0 && self.recvFD >= 0
                let secondsSinceRx = Date().timeIntervalSince(self.lastRxUtc)
                let secondsSinceRecover = Date().timeIntervalSince(self.lastAutoRecoverUtc)
                self.lock.unlock()

                if !hasSockets { continue }

                if secondsSinceRx >= 45 && secondsSinceRecover >= 45 {
                    self.lock.lock()
                    self.lastAutoRecoverUtc = Date()
                    self.lock.unlock()

                    self.addChatLine(prefix: "[System]", message: "No inbound traffic for \(Int(secondsSinceRx))s; auto-reinitializing UDP sockets.")
                    do {
                        try self.initializeNetwork(next: current)
                        self.sendProbePacket()
                    } catch {
                        self.addChatLine(prefix: "[Error]", message: "Auto-recover failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func sendMessage(_ text: String) {
        do {
            let payload = Array(text.utf8)
            try sendPayload(payload)
            addChatLine(prefix: "[\(displayName) \(sendLabel)]", message: text)
        } catch {
            addChatLine(prefix: "[Error]", message: "Send failed: \(error.localizedDescription)")
        }
    }

    private func sendProbePacket() {
        do {
            let payload = Array(probePayloadText.utf8)
            try sendPayload(payload)
            addChatLine(prefix: "[Probe TX]", message: probePayloadText)
        } catch {
            addChatLine(prefix: "[Error]", message: "Probe send failed: \(error.localizedDescription)")
        }
    }

    private func sendPayload(_ payload: [UInt8]) throws {
        lock.lock()
        let fd = sendFD
        let current = config
        lock.unlock()

        guard fd >= 0 else {
            throw NSError(domain: "udp-chat", code: 3, userInfo: [NSLocalizedDescriptionKey: "Network is not initialized."])
        }

        let remoteIP = sendFromA ? current.sideZIP : current.sideAIP
        let remotePort = sendFromA ? current.aToZDestPort : current.zToADestPort

        var remote = sockaddr_in()
        remote.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        remote.sin_family = sa_family_t(AF_INET)
        remote.sin_port = remotePort.bigEndian

        let rc = remoteIP.withCString { inet_pton(AF_INET, $0, &remote.sin_addr) }
        guard rc == 1 else {
            throw NSError(domain: "udp-chat", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid destination IPv4 address: \(remoteIP)"])
        }

        let sent = payload.withUnsafeBytes { ptr in
            withUnsafePointer(to: &remote) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    sendto(fd, ptr.baseAddress, payload.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }

        guard sent == payload.count else {
            throw socketError("sendto() failed")
        }
    }

    private func shutdown() {
        lock.lock()
        let wasRunning = running
        running = false
        closeIfOpen(sendFD)
        closeIfOpen(recvFD)
        sendFD = -1
        recvFD = -1
        lock.unlock()

        if wasRunning {
            addChatLine(prefix: "[System]", message: "Shutting down.")
        }
    }

    private func closeIfOpen(_ fd: Int32) {
        if fd >= 0 { _ = Darwin.close(fd) }
    }

    private func socketError(_ label: String) -> NSError {
        NSError(domain: "udp-chat", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "\(label): \(String(cString: strerror(errno)))"])
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
}

let initialConfig = Config(
    sideAIP: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "127.0.0.1",
    sideZIP: CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "0.0.0.0",
    aToZSourcePort: UInt16(CommandLine.arguments.count > 3 ? (Int(CommandLine.arguments[3]) ?? 7000) : 7000),
    aToZDestPort: UInt16(CommandLine.arguments.count > 4 ? (Int(CommandLine.arguments[4]) ?? 7000) : 7000),
    zToASourcePort: UInt16(CommandLine.arguments.count > 5 ? (Int(CommandLine.arguments[5]) ?? 7001) : 7001),
    zToADestPort: UInt16(CommandLine.arguments.count > 6 ? (Int(CommandLine.arguments[6]) ?? 7001) : 7001)
)

let node = UDPChatNode(
    displayName: "Side Z",
    sendLabel: "Z->A",
    recvLabel: "A->Z",
    probePayloadText: "ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ",
    remoteProbePayloadText: "AAAAA-AAAAA-AAAAA-AAAAA-AAAAA",
    sendFromA: false,
    initialConfig: initialConfig
)

node.run()
