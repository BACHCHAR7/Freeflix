import SwiftUI

struct ContentView: View {
    @AppStorage("serverURL") private var serverURL = "192.168.1.159:3001"
    @State private var showSettings = false
    @State private var tempURL = ""
    
    var body: some View {
        ZStack {
            HomeView()
            
            if showSettings {
                settingsOverlay
            }
        }
        .onAppear { tempURL = serverURL }
        .onLongPressGesture(minimumDuration: 1) {
            showSettings = true
        }
    }
    
    private var settingsOverlay: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
                .onTapGesture { showSettings = false }
            
            VStack(spacing: 40) {
                Text("Configuration du serveur")
                    .font(.system(size: 42, weight: .bold))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Adresse du serveur")
                        .font(.system(size: 22))
                        .foregroundColor(.ffSecondary)
                    
                    TextField("192.168.1.100:3001", text: $tempURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 28))
                        .padding(20)
                        .background(Color.ffCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(width: 500)
                }
                
                HStack(spacing: 30) {
                    Button("Annuler") {
                        tempURL = serverURL
                        showSettings = false
                    }
                    .buttonStyle(SettingsButtonStyle(isPrimary: false))
                    
                    Button("Enregistrer") {
                        serverURL = tempURL
                        showSettings = false
                    }
                    .buttonStyle(SettingsButtonStyle(isPrimary: true))
                }
                .padding(.top, 20)
            }
            .padding(60)
            .background(Color.ffSecondaryBg)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}

struct SettingsButtonStyle: ButtonStyle {
    let isPrimary: Bool
    @Environment(\.isFocused) var isFocused
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 24, weight: .semibold))
            .padding(.horizontal, 50)
            .padding(.vertical, 18)
            .background(isPrimary ? Color.ffAccent : Color.white.opacity(0.2))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 3)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    ContentView()
}
