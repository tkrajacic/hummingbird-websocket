import HummingbirdWSClient
import HummingbirdWSCompression
import Logging

// Autobahn tests
// 1. Framing
// 2. Pings/Pongs
// 3. Reserved bits
// 4. Opcodes
// 5. Fragmentation
// 6. UTF8 handling
// 7. Close handling
// 9. Limits/performance
// 10. Misc
// 12. WebSocket compression (different payloads)
// 13. WebSocket compression (different parameters)

let cases = 1...102

var logger = Logger(label: "TestClient")
logger.logLevel = .trace
do {
    for c in cases {
        logger.info("Case \(c)")
        try await WebSocketClient.connect(
            url: .init("ws://127.0.0.1:9001/runCase?case=\(c)&agent=HB"),
            configuration: .init(maxFrameSize: 1 << 16, extensions: [.perMessageDeflate(maxDecompressedFrameSize: 65536)]),
            logger: logger
        ) { inbound, outbound, _ in
            for try await msg in inbound.messages(maxSize: .max) {
                switch msg {
                case .binary(let buffer):
                    try await outbound.write(.binary(buffer))
                case .text(let string):
                    try await outbound.write(.text(string))
                }
            }
        }
    }
    try await WebSocketClient.connect(url: .init("ws://127.0.0.1:9001/updateReports?agent=HB"), logger: logger) { inbound, _, _ in
        for try await _ in inbound {}
    }
} catch {
    logger.error("Error: \(error)")
}
