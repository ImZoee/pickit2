import SwiftUI

struct MemoryView: View {
    @EnvironmentObject private var model: ProgrammerModel
    var body: some View {
        VStack(spacing: 12) {
            GroupBox {
                HStack {
                    Toggle("Memorie program", isOn: $model.options.programRegions.program).toggleStyle(.checkbox)
                    Toggle("EEPROM", isOn: $model.options.programRegions.eeprom).toggleStyle(.checkbox)
                    Toggle("ID-uri utilizator", isOn: $model.options.programRegions.ids).toggleStyle(.checkbox)
                    Toggle("Biți configurare", isOn: $model.options.programRegions.configuration).toggleStyle(.checkbox)
                    Spacer()
                    Text("Previzualizare HEX · primii 1 KB").font(.caption).foregroundStyle(.secondary)
                }
            }
            GroupBox {
                ScrollView([.horizontal, .vertical]) {
                    LazyVStack(alignment: .leading, spacing: 3) {
                        if model.memoryPreview.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "doc.text.magnifyingglass").font(.system(size: 34)).foregroundStyle(.secondary)
                                Text("Niciun firmware selectat").font(.headline)
                                Text("Selectează un fișier Intel HEX pentru a-i verifica conținutul.").foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, minHeight: 260)
                        } else {
                            ForEach(Array(model.memoryPreview.enumerated()), id: \.offset) { _, line in
                                Text(line).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                            }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(8)
                }
            }.frame(maxHeight: .infinity)
        }.padding(.vertical, 10)
    }
}

struct ConfigurationView: View {
    @EnvironmentObject private var model: ProgrammerModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SettingsCard("Alimentare și semnale", icon: "bolt.fill") {
                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
                        GridRow { Toggle("Setează manual VDD", isOn: $model.options.overrideVDD); TextField("Volți", text: $model.options.vdd).frame(width: 90) }
                        GridRow { Toggle("Ținta are alimentare externă", isOn: $model.options.externalPower); TextField("Prag opțional", text: $model.options.externalPowerThreshold).frame(width: 140) }
                        GridRow { Toggle("Setează manual VPP", isOn: $model.options.overrideVPP); TextField("Volți", text: $model.options.vpp).frame(width: 90) }
                        GridRow { Toggle("Intrare în programare cu VPP primul", isOn: $model.options.vppFirst); EmptyView() }
                        GridRow { Toggle("Menține ținta alimentată după operație", isOn: $model.options.powerAfter); Toggle("Eliberează pinul /MCLR", isOn: $model.options.releaseMCLR) }
                    }.toggleStyle(.checkbox)
                }
                SettingsCard("Comportament la programare", icon: "gearshape.2.fill") {
                    VStack(alignment: .leading, spacing: 9) {
                        Toggle("Păstrează conținutul EEPROM", isOn: $model.options.preserveEEPROM)
                        Toggle("Scrie inclusiv zonele goale până la ultima adresă utilizată", isOn: $model.options.writeAllThroughLastAddress)
                        Toggle("Dezactivează Programming Executive pentru PIC24/dsPIC33", isOn: $model.options.disablePE)
                        Toggle("Verifică imediat fiecare regiune programată", isOn: $model.options.immediateVerify)
                        HStack { Text("Viteză programare"); Slider(value: Binding(get: { Double(model.options.programmingSpeed) }, set: { model.options.programmingSpeed = Int($0) }), in: 1...16, step: 1); Text("Nivel \(model.options.programmingSpeed)").monospacedDigit().frame(width: 55) }
                    }.toggleStyle(.checkbox)
                }
                SettingsCard("Fișiere de sistem", icon: "folder.fill") {
                    PathRow(label: "Bază dispozitive", path: model.options.deviceFilePath, action: model.chooseDeviceFile)
                    PathRow(label: "Firmware programator", path: model.options.firmwarePath, action: model.chooseFirmware)
                }
            }.padding(.vertical, 10)
        }
    }
}

struct AdvancedView: View {
    @EnvironmentObject private var model: ProgrammerModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.shield.fill").foregroundStyle(.orange)
                    Text("Modul expert oferă acces direct la toate comenzile pk2cmd. Folosește-l numai dacă înțelegi efectul opțiunilor selectate.")
                        .font(.callout)
                }.padding(12).frame(maxWidth: .infinity, alignment: .leading).background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                SettingsCard("Operații avansate · C, E, G, M, Y", icon: "play.square.stack") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack { Toggle("Verificare memorie goală (-C)", isOn: $model.options.blankCheck); Toggle("Ștergere (-E)", isOn: $model.options.erase); Toggle("Programare (-M)", isOn: $model.options.program); Toggle("Verificare (-Y)", isOn: $model.options.verify) }.toggleStyle(.checkbox)
                        RegionEditor(title: "Regiuni programate", regions: $model.options.programRegions)
                        RegionEditor(title: "Regiuni verificate", regions: $model.options.verifyRegions)
                        Divider()
                        HStack {
                            Toggle("Citire (-G)", isOn: $model.options.readEnabled).toggleStyle(.checkbox)
                            Picker("", selection: $model.options.readMode) { ForEach(ReadMode.allCases) { Text($0.rawValue).tag($0) } }.labelsHidden().frame(width: 170)
                            if model.options.readMode.needsPath { TextField("Calea fișierului rezultat", text: $model.options.readPath) }
                            if model.options.readMode.supportsRange { TextField("Interval HEX x-y", text: $model.options.readRange) }
                        }
                    }
                }
                SettingsCard("Identificare și raportare · H, I, J, K, N, S", icon: "text.viewfinder") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack { Toggle("Afișează ID dispozitiv (-I)", isOn: $model.options.showDeviceID); Toggle("Afișează checksum (-K)", isOn: $model.options.showChecksum); Toggle("Raportează progresul (-J)", isOn: $model.options.progressUpdates); TextField("N / linii", text: $model.options.progressLines).frame(width: 90) }.toggleStyle(.checkbox)
                        HStack { Text("Programator utilizat"); Picker("", selection: $model.options.unitSelection) { ForEach(UnitSelection.allCases) { Text($0.rawValue).tag($0) } }.labelsHidden(); if model.options.unitSelection == .unitID { TextField("ID programator", text: $model.options.unitID) } }
                        HStack { Toggle("Atribuie ID programatorului (-N)", isOn: $model.options.setUnitID).toggleStyle(.checkbox); TextField("Maximum 14 caractere", text: $model.options.newUnitID).disabled(!model.options.setUnitID) }
                        HStack { Text("Întârziere la final (-H)"); TextField("secunde sau K", text: $model.options.exitDelay).frame(width: 150); Spacer() }
                    }
                }
                SettingsCard("Calibrare și EEPROM serial · U, #", icon: "waveform.path.ecg") {
                    HStack {
                        Toggle("Programează OSCCAL (-U)", isOn: $model.options.programOSCCAL).toggleStyle(.checkbox)
                        TextField("Valoare HEX", text: $model.options.osccal).frame(width: 120)
                        Divider().frame(height: 20)
                        Toggle("Adresă I²C (-#)", isOn: $model.options.overrideI2CAddress).toggleStyle(.checkbox)
                        TextField("0…7 or 0x08…0x77", text: $model.options.i2cAddress).frame(width: 160)
                    }
                }
                SettingsCard("Argumente CLI suplimentare", icon: "terminal.fill") {
                    TextField("Argumente pk2cmd adiționale", text: $model.options.rawArguments)
                    Text("Destinat depanării și combinațiilor rare. Argumentele sunt transmise direct către pk2cmd; nu este utilizat un shell.").font(.caption).foregroundStyle(.secondary)
                }
                SettingsCard("Comandă rezultată", icon: "chevron.left.forwardslash.chevron.right") {
                    ScrollView(.horizontal) { Text(model.commandPreview).font(.system(.callout, design: .monospaced)).textSelection(.enabled).padding(.vertical, 4) }
                    HStack {
                        Button("Rulează comanda configurată") { model.runConfigured(); model.selectedTab = 3 }.buttonStyle(.borderedProminent).disabled(model.isRunning)
                        Menu("Ajutor pentru opțiune") {
                            ForEach(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ#"), id: \.self) { option in Button(String(option)) { model.showHelp(String(option)) } }
                        }
                        Spacer()
                    }
                }
            }.padding(.vertical, 10)
        }
    }
}

struct ConsoleView: View {
    @EnvironmentObject private var model: ProgrammerModel
    var body: some View {
        VStack(spacing: 8) {
            HStack { Text("Jurnal pk2cmd").font(.headline); Spacer(); if let code = model.exitCode { Text("Cod rezultat: \(code)").font(.caption).foregroundStyle(code == 0 ? .green : .red) }; Button("Golește jurnalul") { model.console = "" } }
            ScrollView([.horizontal, .vertical]) {
                Text(model.console.isEmpty ? "Nu există încă operații în jurnal." : model.console)
                    .font(.system(.callout, design: .monospaced)).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading).padding(12)
            }.background(Color(nsColor: .textBackgroundColor)).clipShape(RoundedRectangle(cornerRadius: 8))
        }.padding(.vertical, 10)
    }
}

private struct RegionEditor: View {
    let title: String
    @Binding var regions: MemoryRegions
    var body: some View {
        HStack { Text(title).frame(width: 130, alignment: .leading); Toggle("Program", isOn: $regions.program); Toggle("EEPROM", isOn: $regions.eeprom); Toggle("ID-uri", isOn: $regions.ids); Toggle("Configurare", isOn: $regions.configuration); Text(regions.isEmpty ? "tot" : regions.suffix).font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary) }.toggleStyle(.checkbox)
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String, icon: String, content: Content
    init(_ title: String, icon: String, @ViewBuilder content: () -> Content) { self.title = title; self.icon = icon; self.content = content() }
    var body: some View { GroupBox { VStack(alignment: .leading, spacing: 10) { Label(title, systemImage: icon).font(.headline); Divider(); content }.frame(maxWidth: .infinity, alignment: .leading).padding(4) } }
}

private struct PathRow: View {
    let label: String, path: String, action: () -> Void
    var body: some View { HStack { Text(label).frame(width: 140, alignment: .leading); Text(path.isEmpty ? "Neselectat" : path).lineLimit(1).truncationMode(.middle).foregroundStyle(path.isEmpty ? .secondary : .primary); Spacer(); Button("Selectează…", action: action) } }
}
