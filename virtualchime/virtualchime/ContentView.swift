import SwiftUI
import CocoaMQTT

struct ContentView: View {
    @ObservedObject var appState = MQTTManager.shared().currentAppState
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            VStack {
                // Display connection status
                HStack {
                    Image(systemName: appState.appConnectionState.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(appState.appConnectionState.isConnected ? .green : .red)
                        .padding()
                    Text(appState.appConnectionState.description)
                        .foregroundColor(appState.appConnectionState.isConnected ? .green : .red)
                }

                // Display MQTT messages history
                ScrollView {
                    Text(appState.historyText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { // Ensure correct placement
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
