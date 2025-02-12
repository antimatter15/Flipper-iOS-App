public enum Message {
    case decodeError
    case screenFrame(ScreenFrame)
    case reboot(RebootMode)
    case unknown(String)

    public enum RebootMode {
        case os
        case dfu
        case update
    }
}

extension Message {
    init(decoding main: PB_Main) {
        guard main.commandStatus != .errorDecode else {
            self = .decodeError
            return
        }
        switch main.content {
        case .guiScreenFrame(let response):
            self.init(decoding: response)
        default:
            self = .unknown("\(main)")
        }
    }

    init(decoding response: PBGui_ScreenFrame) {
        guard let frame = ScreenFrame(.init(response.data)) else {
            self = .screenFrame(.init())
            return
        }
        self = .screenFrame(frame)
    }
}

extension Message {
    func serialize() -> PB_Main {
        switch self {
        case .decodeError:
            return .with {
                $0.commandStatus = .errorDecode
            }
        case .screenFrame(let screenFrame):
            return .with {
                $0.guiScreenFrame = .with {
                    $0.data = .init(screenFrame.bytes)
                }
            }
        case .reboot(let mode):
            return .with {
                $0.systemRebootRequest = .with {
                    $0.mode = .init(mode)
                }
            }
        case .unknown:
            fatalError("uncreachable")
        }
    }
}
