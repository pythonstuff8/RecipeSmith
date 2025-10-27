import SwiftUI
import Combine

struct LoadingView: View {
    @StateObject private var viewModel = LoadingViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.statusText)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            
            ProgressView(value: viewModel.progress, total: 100)
                .progressViewStyle(.linear)
                .frame(width: 200)
                .tint(.blue)
            
            Text("\(Int(viewModel.progress))%")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            viewModel.startProgress()
        }
        .onDisappear {
            viewModel.stopProgress()
        }
    }
}

class LoadingViewModel: ObservableObject {
    @Published var progress: Double = 0
    @Published var statusText: String = "Starting recipe generation..."
    
    private var timer: Timer?
    
    func startProgress() {
        progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    func stopProgress() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateProgress() {
        guard progress < 100 else {
            stopProgress()
            return
        }
        
        progress += 0.5
        updateStatusText()
    }
    
    private func updateStatusText() {
        switch progress {
        case 0..<20:
            statusText = "Preparing recipe request..."
        case 20..<40:
            statusText = "Generating recipe..."
        case 40..<60:
            statusText = "Creating recipe image..."
        case 60..<80:
            statusText = "Processing image..."
        case 80..<90:
            statusText = "Finalizing recipe..."
        default:
            statusText = "Almost done... Please Wait 30 More Seconds If it doesn't load"
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
