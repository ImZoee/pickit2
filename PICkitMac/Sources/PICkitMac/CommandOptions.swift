import Foundation

enum PartSelection: String, CaseIterable, Identifiable {
    case explicit = "Model exact"
    case autoAll = "Detectare automată"
    case autoFamily = "Detectare după familie"
    case none = "Fără selecție"
    var id: String { rawValue }
}

enum UnitSelection: String, CaseIterable, Identifiable {
    case first = "Primul conectat"
    case unitID = "După ID"
    case list = "Listează programatoarele"
    case listFirmware = "Listează și versiunile"
    var id: String { rawValue }
}

struct MemoryRegions {
    var program = false
    var eeprom = false
    var ids = false
    var configuration = false

    var suffix: String {
        (program ? "P" : "") + (eeprom ? "E" : "") +
        (ids ? "I" : "") + (configuration ? "C" : "")
    }

    var isEmpty: Bool { suffix.isEmpty }
}

enum ReadMode: String, CaseIterable, Identifiable {
    case hexFile = "Fișier HEX"
    case rawFile = "Fișier binar"
    case program = "Memorie program"
    case eeprom = "EEPROM"
    case ids = "Memorie ID"
    case configuration = "Configurare"
    var id: String { rawValue }

    var code: String {
        switch self {
        case .hexFile: return "F"
        case .rawFile: return "U"
        case .program: return "P"
        case .eeprom: return "E"
        case .ids: return "I"
        case .configuration: return "C"
        }
    }

    var needsPath: Bool { self == .hexFile || self == .rawFile }
    var supportsRange: Bool { self == .program || self == .eeprom }
}

struct CommandOptions {
    // A, B, F, P and S — context
    var vdd = "5.0"
    var overrideVDD = false
    var deviceFilePath = ""
    var hexFilePath = ""
    var partSelection: PartSelection = .explicit
    var partName = "PIC16F887"
    var familyID = ""
    var unitSelection: UnitSelection = .first
    var unitID = ""

    // C, D, E, G, M, Y — operations
    var blankCheck = false
    var firmwarePath = ""
    var erase = false
    var readEnabled = false
    var readMode: ReadMode = .hexFile
    var readPath = ""
    var readRange = ""
    var program = false
    var programRegions = MemoryRegions()
    var immediateVerify = false
    var verify = false
    var verifyRegions = MemoryRegions()

    // H–O
    var exitDelay = ""
    var showDeviceID = false
    var progressUpdates = false
    var progressLines = "N"
    var showChecksum = false
    var programmingSpeed = 1
    var setUnitID = false
    var newUnitID = ""
    var writeAllThroughLastAddress = false

    // Q–Z and #
    var disablePE = false
    var releaseMCLR = false
    var powerAfter = false
    var programOSCCAL = false
    var osccal = ""
    var overrideVPP = false
    var vpp = ""
    var externalPower = false
    var externalPowerThreshold = ""
    var vppFirst = false
    var preserveEEPROM = false
    var overrideI2CAddress = false
    var i2cAddress = ""
    var rawArguments = ""

    func arguments() -> [String] {
        var args: [String] = []

        if !deviceFilePath.isEmpty { args.append("-B\(deviceFilePath)") }

        switch unitSelection {
        case .first: break
        case .unitID where !unitID.isEmpty: args.append("-S\(unitID)")
        case .list: return ["-S"]
        case .listFirmware: return ["-S#"]
        default: break
        }

        if !firmwarePath.isEmpty { args.append("-D\(firmwarePath)") }
        if setUnitID { return args + ["-N\(newUnitID)"] }

        switch partSelection {
        case .explicit where !partName.isEmpty: args.append("-P\(partName)")
        case .autoAll: args.append("-P")
        case .autoFamily: args.append("-PF\(familyID)")
        case .none: break
        default: break
        }

        if overrideVDD { args.append("-A\(vdd)") }
        if !hexFilePath.isEmpty { args.append("-F\(hexFilePath)") }
        if progressUpdates { args.append("-J\(progressLines)") }
        if programmingSpeed > 1 { args.append("-L\(programmingSpeed)") }
        if writeAllThroughLastAddress { args.append("-O") }
        if disablePE { args.append("-Q") }
        if overrideVPP, !vpp.isEmpty { args.append("-V\(vpp)") }
        if externalPower { args.append("-W\(externalPowerThreshold)") }
        if vppFirst { args.append("-X") }
        if preserveEEPROM { args.append("-Z") }
        if overrideI2CAddress, !i2cAddress.isEmpty { args.append("-#\(i2cAddress)") }

        if blankCheck { args.append("-C") }
        if programOSCCAL, !osccal.isEmpty { args.append("-U\(osccal)") }
        if erase { args.append("-E") }
        if program {
            let suffix = (immediateVerify ? "+" : "") + programRegions.suffix
            args.append("-M\(suffix)")
        }
        if verify {
            if verifyRegions.isEmpty {
                args.append("-Y")
            } else {
                for region in verifyRegions.suffix { args.append("-Y\(region)") }
            }
        }
        if readEnabled {
            let value: String
            if readMode.needsPath { value = readPath }
            else if readMode.supportsRange { value = readRange }
            else { value = "" }
            args.append("-G\(readMode.code)\(value)")
        }
        if showDeviceID { args.append("-I") }
        if showChecksum { args.append("-K") }
        if releaseMCLR { args.append("-R") }
        if powerAfter { args.append("-T") }
        if !exitDelay.isEmpty { args.append("-H\(exitDelay)") }
        args.append(contentsOf: splitCommandLine(rawArguments))
        return args
    }
}

private func splitCommandLine(_ input: String) -> [String] {
    var result: [String] = []
    var current = ""
    var quote: Character?
    var escaping = false
    for char in input {
        if escaping { current.append(char); escaping = false; continue }
        if char == "\\" { escaping = true; continue }
        if let active = quote {
            if char == active { quote = nil } else { current.append(char) }
        } else if char == "\"" || char == "'" {
            quote = char
        } else if char.isWhitespace {
            if !current.isEmpty { result.append(current); current = "" }
        } else { current.append(char) }
    }
    if !current.isEmpty { result.append(current) }
    return result
}

extension String {
    var shellQuoted: String {
        if rangeOfCharacter(from: .whitespacesAndNewlines) == nil { return self }
        return "\"\(replacingOccurrences(of: "\"", with: "\\\""))\""
    }
}
