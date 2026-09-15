import SwiftUI

@main
struct PICkitMacApp: App {
    @StateObject private var model = ProgrammerModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 1080, minHeight: 720)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Programmer") {
                Button("Detectează dispozitivul") { model.request(.detect) }
                    .keyboardShortcut("d", modifiers: [.command])
                Divider()
                Button("Citește…") { model.request(.read) }
                    .keyboardShortcut("r", modifiers: [.command])
                Button("Scrie firmware-ul") { model.request(.write) }
                    .keyboardShortcut("w", modifiers: [.command])
                Button("Verifică") { model.request(.verify) }
                    .keyboardShortcut("v", modifiers: [.command])
                Button("Șterge memoria") { model.request(.erase) }
                Button("Verifică memoria goală") { model.request(.blankCheck) }
            }
        }
    }
}
