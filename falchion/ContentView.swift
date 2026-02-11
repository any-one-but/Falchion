import SwiftUI

struct ContentView: View {
    var body: some View {
        FalchionShellView()
    }
}

#Preview {
    ContentView()
        .environmentObject(FalchionAppState())
}
