import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: ProgrammerModel

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            Divider()
            HStack(spacing: 0) {
                sidebar
                Divider()
                VStack(spacing: 0) {
                    deviceHeader
                    statusStrip
                    quickActions
                    Divider()
                    TabView(selection: $model.selectedTab) {
                        MemoryView().tabItem { Label("Firmware", systemImage: "memorychip") }.tag(0)
                        ConfigurationView().tabItem { Label("Configurare", systemImage: "switch.2") }.tag(1)
                        AdvancedView().tabItem { Label("Mod expert", systemImage: "slider.horizontal.3") }.tag(2)
                        ConsoleView().tabItem { Label("Jurnal operații", systemImage: "terminal") }.tag(3)
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .confirmationDialog(
            confirmationTitle,
            isPresented: Binding(
                get: { model.pendingConfirmation != nil },
                set: { if !$0 { model.pendingConfirmation = nil } }
            ),
            titleVisibility: .visible
        ) {
            if model.pendingConfirmation == .write {
                Button("Scrie firmware-ul", role: .destructive) { model.confirmPendingOperation() }
            } else if model.pendingConfirmation == .erase {
                Button("Șterge definitiv memoria", role: .destructive) { model.confirmPendingOperation() }
            }
            Button("Anulează", role: .cancel) { model.pendingConfirmation = nil }
        } message: {
            Text(confirmationMessage)
        }
        .alert("Nu putem continua", isPresented: Binding(
            get: { model.alertMessage != nil },
            set: { if !$0 { model.alertMessage = nil } }
        )) {
            Button("Am înțeles") { model.alertMessage = nil }
        } message: { Text(model.alertMessage ?? "") }
    }

    private var titleBar: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(Color.accentColor.gradient)
                Image(systemName: "memorychip.fill").foregroundStyle(.white)
            }.frame(width: 34, height: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text("PICkit Mac Programmer").font(.headline)
                Text("Programare și verificare firmware").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Circle().fill(model.isRunning ? .orange : model.exitCode == 0 ? .green : .secondary).frame(width: 8, height: 8)
            Text(model.status).font(.callout).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18).frame(height: 54)
        .background(.ultraThinMaterial)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            FieldLabel("Pregătire")
            ReadinessRow(number: 1, title: "Motor de programare", detail: model.isEngineReady ? "pk2cmd este disponibil" : "Necesită configurare", complete: model.isEngineReady)
            if !model.isEngineReady { Button("Selectează pk2cmd…") { model.chooseExecutable() }.controlSize(.small) }
            Divider()
            ReadinessRow(number: 2, title: "Microcontroler", detail: model.selectedTarget, complete: model.options.partSelection != .none && (model.options.partSelection != .explicit || !model.options.partName.isEmpty))
            FieldLabel("Metodă de selectare")
            Picker("", selection: $model.options.partSelection) {
                Text("Introdu modelul exact").tag(PartSelection.explicit)
                Text("Detectare automată").tag(PartSelection.autoAll)
                Text("Detectare într-o familie").tag(PartSelection.autoFamily)
            }.labelsHidden()
            if model.options.partSelection == .explicit {
                TextField("Exemplu: PIC16F887", text: $model.options.partName)
            } else if model.options.partSelection == .autoFamily {
                TextField("ID-ul familiei", text: $model.options.familyID)
            }
            Button { model.request(.detect) } label: {
                Label("Detectează acum", systemImage: "scope").frame(maxWidth: .infinity)
            }.buttonStyle(.borderedProminent).disabled(model.isRunning)
            Divider()
            ReadinessRow(number: 3, title: "Fișier firmware", detail: model.hasFirmware ? URL(fileURLWithPath: model.options.hexFilePath).lastPathComponent : "Niciun fișier selectat", complete: model.hasFirmware)
            Button(model.hasFirmware ? "Schimbă fișierul…" : "Selectează firmware…") { model.chooseHexFile() }
                .frame(maxWidth: .infinity)
            Spacer()
            Button { model.selectedTab = 1 } label: { Label("Configurare", systemImage: "gearshape") }
                .buttonStyle(.plain).foregroundStyle(.secondary)
            Button { model.showHelp() } label: { Label("Ajutor pk2cmd", systemImage: "questionmark.circle") }
                .buttonStyle(.plain).foregroundStyle(.secondary)
        }
        .padding(16).frame(width: 252)
    }

    private var deviceHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text(model.selectedTarget)
                    .font(.title3.weight(.semibold))
                HStack(spacing: 18) {
                    Label("PICkit 2 / 3 / PKOB", systemImage: "externaldrive.connected.to.line.below")
                    Label(model.options.externalPower ? "Alimentare externă" : "Alimentare din programator", systemImage: "bolt")
                }.font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text("TENSIUNE ȚINTĂ (VDD)").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                HStack(spacing: 5) {
                    TextField("5.0", text: $model.options.vdd).frame(width: 48).multilineTextAlignment(.trailing)
                    Text("V")
                    Toggle("Valoare manuală", isOn: $model.options.overrideVDD).labelsHidden().help("Activează pentru a înlocui tensiunea recomandată de baza de dispozitive.")
                }
            }
        }.padding(16)
    }

    private var statusStrip: some View {
        HStack {
            Image(systemName: model.isRunning ? "arrow.triangle.2.circlepath" : model.exitCode == 0 ? "checkmark.circle.fill" : "info.circle.fill")
            Text(model.status).fontWeight(.medium)
            Spacer()
            if model.isRunning { ProgressView().controlSize(.small) }
        }
        .foregroundStyle(model.isRunning ? Color.orange : model.exitCode == 0 ? Color.green : Color.accentColor)
        .padding(.horizontal, 14).frame(height: 38)
        .background((model.isRunning ? Color.orange : model.exitCode == 0 ? Color.green : Color.accentColor).opacity(0.11))
        .padding(.horizontal, 12)
    }

    private var quickActions: some View {
        HStack(spacing: 8) {
            ActionButton("Citește", "arrow.down.doc", .read, help: "Citește memoria dispozitivului și salvează rezultatul într-un fișier HEX.")
            ActionButton("Scrie firmware", "arrow.up.doc", .write, prominent: true, help: "Scrie fișierul HEX selectat și verifică automat rezultatul.")
            ActionButton("Verifică", "checkmark.shield", .verify, help: "Compară dispozitivul cu fișierul HEX fără să modifice memoria.")
            ActionButton("Șterge", "eraser", .erase, help: "Șterge memoria dispozitivului după confirmare.")
            ActionButton("Memorie goală?", "doc.badge.magnifyingglass", .blankCheck, help: "Verifică dacă memoria dispozitivului este complet goală.")
            Spacer()
            if model.isRunning { Button("Oprește operația", role: .destructive) { model.stop() } }
        }.padding(12)
    }

    private var confirmationTitle: String {
        model.pendingConfirmation == .erase ? "Ștergi memoria dispozitivului?" : "Scrii firmware-ul pe dispozitiv?"
    }

    private var confirmationMessage: String {
        if model.pendingConfirmation == .erase {
            return "Conținutul existent din \(model.selectedTarget) va fi șters definitiv."
        }
        let file = URL(fileURLWithPath: model.options.hexFilePath).lastPathComponent
        return "Fișierul „\(file)” va fi scris pe \(model.selectedTarget), apoi verificat. Nu deconecta programatorul în timpul operației."
    }
}

private struct ActionButton: View {
    @EnvironmentObject var model: ProgrammerModel
    let title: String, icon: String, operation: QuickOperation, prominent: Bool, help: String
    init(_ title: String, _ icon: String, _ operation: QuickOperation, prominent: Bool = false, help: String = "") {
        self.title = title; self.icon = icon; self.operation = operation; self.prominent = prominent; self.help = help
    }
    var body: some View {
        if prominent {
            button.buttonStyle(.borderedProminent)
        } else {
            button.buttonStyle(.bordered)
        }
    }

    private var button: some View {
        Button { model.request(operation) } label: { Label(title, systemImage: icon).frame(minWidth: 78) }
            .disabled(model.isRunning).help(help)
    }
}

private struct ReadinessRow: View {
    let number: Int, title: String, detail: String, complete: Bool
    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                Circle().fill(complete ? Color.green : Color.secondary.opacity(0.15))
                if complete { Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white) }
                else { Text("\(number)").font(.caption.bold()).foregroundStyle(.secondary) }
            }.frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.callout.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
            }
        }
    }
}

struct FieldLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View { Text(text.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(.secondary) }
}
