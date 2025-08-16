// MARK: - Examples/MLX-Demo-App/MLXCacheDemo/ContentView.swift

import SwiftUI
import Foundation
import Combine
import ECMFramework

// Import MLX frameworks - check these imports
#if canImport(MLX)
import MLX
#endif

#if canImport(MLXLLM)
import MLXLLM
#endif

#if canImport(MLXLMCommon)
import MLXLMCommon
#endif

// MARK: - MLX Context Adapter for ECM Framework

#if canImport(MLXLLM)
/// Adapter that makes MLX ModelContext conform to ECMModelContext
struct MLXContextAdapter: ECMModelContext {
    private let mlxContext: ModelContext
    
    init(_ context: ModelContext) {
        self.mlxContext = context
    }
    
    func encode(text: String) async throws -> [Int] {
        return try await mlxContext.tokenizer.encode(text: text)
    }
    
    func decode(tokens: [Int]) -> String {
        return mlxContext.tokenizer.decode(tokens: tokens)
    }
}
#else
// Fallback adapter for when MLX is not available
struct MockMLXContextAdapter: ECMModelContext {
    func encode(text: String) async throws -> [Int] {
        // Simple mock tokenization - just return character codes
        return text.utf8.map { Int($0) }
    }
    
    func decode(tokens: [Int]) -> String {
        let bytes = tokens.compactMap { UInt8(exactly: $0) }
        return String(bytes: bytes, encoding: .utf8) ?? ""
    }
}
#endif

// MARK: - Keyboard Height Publisher
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ -> CGFloat in 0 }
        
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

// MARK: - MLX Service using ECM Framework
@MainActor
class MLXCacheService: ObservableObject {
    @Published var output = ""
    @Published var isLoading = false
    @Published var modelInfo = "No model loaded"
    @Published var memoryUsage = "0 MB"
    
    #if canImport(MLXLLM)
    private var modelContainer: ModelContainer?
    
    // Try multiple model configurations in order of preference
    private let modelConfigs = [
        ModelConfiguration(id: "mlx-community/Qwen2.5-0.5B-Instruct-4bit"),
        ModelConfiguration(id: "mlx-community/SmolLM2-360M-Instruct-4bit"),
        ModelConfiguration(id: "mlx-community/Llama-3.2-1B-Instruct-4bit")
    ]
    #endif
    
    func loadModel() async {
        #if canImport(MLXLLM)
        guard modelContainer == nil else { return }
        
        isLoading = true
        
        // Try each model configuration
        for (index, config) in modelConfigs.enumerated() {
            do {
                modelInfo = "Trying model \(index + 1)/\(modelConfigs.count): \(config.id)"
                
                // Set memory limits for mobile
                #if canImport(MLX)
                MLX.GPU.set(cacheLimit: 256 * 1024 * 1024) // 256MB cache limit
                #endif
                
                print("Attempting to load model: \(config.id)")
                
                modelContainer = try await LLMModelFactory.shared.loadContainer(
                    configuration: config
                ) { progress in
                    Task { @MainActor in
                        self.modelInfo = "Loading \(config.id): \(Int(progress.fractionCompleted * 100))%"
                    }
                }
                
                modelInfo = "✅ Model loaded: \(config.id)"
                updateMemoryUsage()
                isLoading = false
                return // Success, exit the loop
                
            } catch {
                print("Failed to load \(config.id): \(error)")
                modelInfo = "❌ Failed \(config.id): \(error.localizedDescription)"
                
                // Continue to next model if this one fails
                if index == modelConfigs.count - 1 {
                    // Last model failed
                    modelInfo = "❌ All models failed. Error: \(error.localizedDescription)"
                }
            }
        }
        
        isLoading = false
        #else
        modelInfo = "❌ MLX framework not available. Please add MLX package dependency."
        isLoading = false
        #endif
    }
    
    func processMessage(_ message: String) async {
        #if canImport(MLXLLM)
        guard let container = modelContainer else {
            output = "Model not loaded. Please wait for model to load."
            return
        }
        
        print("Processing message: \(message)")
        
        do {
            let result = try await container.perform { context in
                // ✨ Use ECM Framework with MLX adapter
                let ecmContext = MLXContextAdapter(context)
                let ecmResult = try await ECMFramework.shared.processMessage(message, context: ecmContext)
                
                // If no clean input, just return confirmation
                guard ecmResult.hasCleanInput else {
                    return "✅ Cache operation completed successfully."
                }
                
                print("Final input for generation: \(ecmResult.finalPrompt)")
                
                // Create input for generation
                let userInput = UserInput(prompt: ecmResult.finalPrompt)
                let lmInput = try await context.processor.prepare(input: userInput)
                
                var generatedText = ""
                
                print("Starting generation...")
                
                let _ = try MLXLMCommon.generate(
                    input: lmInput,
                    parameters: GenerateParameters(
                        maxTokens: 150,
                        temperature: 0.1,
                        topP: 0.9,
                        repetitionPenalty: 1.1
                    ),
                    context: context
                ) { tokens in
                    let fullText = context.tokenizer.decode(tokens: tokens)
                    print("Generated text: '\(fullText)'")
                    generatedText = fullText
                    
                    Task { @MainActor in
                        self.output = generatedText
                    }
                    
                    // Check for natural stopping points
                    if fullText.contains("\n\n") || (fullText.contains(".") && fullText.count > 50) {
                        print("Found natural stopping point")
                        return .stop
                    }
                    
                    return .more
                }
                
                return generatedText.isEmpty ? "⚠️ Empty response generated" : generatedText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            output = result
            updateMemoryUsage()
            
        } catch {
            print("Error: \(error)")
            output = "Error: \(error.localizedDescription)"
        }
        #else
        // Fallback for when MLX is not available - just test ECM functionality
        print("Processing message with mock MLX: \(message)")
        
        do {
            let mockContext = MockMLXContextAdapter()
            let ecmResult = try await ECMFramework.shared.processMessage(message, context: mockContext)
            
            guard ecmResult.hasCleanInput else {
                output = "✅ Cache operation completed successfully. (Mock Mode - MLX not available)"
                return
            }
            
            output = "Mock response: \(ecmResult.finalPrompt) (MLX not available - add MLX package for real generation)"
        } catch {
            output = "Error: \(error.localizedDescription)"
        }
        #endif
    }
    
    private func updateMemoryUsage() {
        #if canImport(MLX)
        let snapshot = MLX.GPU.snapshot()
        memoryUsage = "\(snapshot.cacheMemory / 1024 / 1024) MB"
        #else
        memoryUsage = "N/A"
        #endif
    }
}

// MARK: - Main App View
struct ContentView: View {
    @StateObject private var mlxService = MLXCacheService()
    @State private var inputText = ""
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        // Header - Fixed at top
                        VStack(spacing: 8) {
                            Text("MLX Explicit Cache Demo")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            HStack {
                                Text(mlxService.modelInfo)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("Cache: \(mlxService.memoryUsage)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        
                        // Scrollable content area
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // ✨ Use ECM Framework Cache Status View
                                ECMCacheStatusView()
                                    .id("cacheStatus")
                                
                                // Output Section
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Output:")
                                        .font(.headline)
                                    
                                    Text(mlxService.output.isEmpty ? "Ready for input..." : mlxService.output)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .background(Color(.systemGray5))
                                        .cornerRadius(8)
                                        .id("output")
                                }
                                .padding(.horizontal)
                                
                                // Dynamic spacer to account for keyboard
                                Color.clear.frame(height: max(20, keyboardHeight + 20))
                                    .id("spacer")
                            }
                        }
                        .frame(maxHeight: .infinity)
                        
                        // Input Section - Fixed at bottom with keyboard handling
                        VStack(spacing: 12) {
                            // Example buttons
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    Button("📄 Cache Document") {
                                        inputText = "[System Cache: legal_doc] This comprehensive legal agreement between TechCorp and ClientCorp covers intellectual property rights, liability limitations, dispute resolution procedures, and confidentiality requirements. The contract is effective for 3 years."
                                        isInputFocused = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                proxy.scrollTo("inputArea", anchor: .bottom)
                                            }
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                    
                                    Button("❓ Ask Question") {
                                        inputText = "Based on cache reference: legal_doc, what is the contract duration?"
                                        isInputFocused = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                proxy.scrollTo("inputArea", anchor: .bottom)
                                            }
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                    
                                    Button("🧹 Clean Cache") {
                                        inputText = "[System Clean Cache: legal_doc]"
                                        isInputFocused = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                proxy.scrollTo("inputArea", anchor: .bottom)
                                            }
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                    
                                    Button("🔄 Multiple Cache") {
                                        inputText = "[System Cache: product] iPhone 15 Pro features A17 Pro chip, titanium design, and 48MP camera."
                                        isInputFocused = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                proxy.scrollTo("inputArea", anchor: .bottom)
                                            }
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .font(.caption)
                                }
                                .padding(.horizontal)
                            }
                            
                            // Input field and send button
                            HStack(spacing: 8) {
                                TextField("Enter cache directive or question...", text: $inputText, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($isInputFocused)
                                    .lineLimit(1...4)
                                
                                Button("Send") {
                                    Task {
                                        await mlxService.processMessage(inputText)
                                        inputText = ""
                                        isInputFocused = false
                                        
                                        // Scroll to output after sending
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            withAnimation(.easeInOut(duration: 0.5)) {
                                                proxy.scrollTo("output", anchor: .bottom)
                                            }
                                        }
                                    }
                                }
                                .disabled(mlxService.isLoading || inputText.isEmpty)
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.horizontal)
                            .id("inputArea")
                        }
                        .padding(.bottom, max(8, keyboardHeight > 0 ? 8 : 8))
                        .background(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await mlxService.loadModel()
        }
        .onReceive(Publishers.keyboardHeight) { height in
            withAnimation(.easeInOut(duration: 0.3)) {
                self.keyboardHeight = height
            }
        }
    }
}

// MARK: - ECM Cache Status View (from Framework)
struct ECMCacheStatusView: View {
    @ObservedObject private var cacheManager = ExplicitCacheManager.shared
    
    var body: some View {
        if !cacheManager.caches.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Active Caches (\(cacheManager.caches.count))")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Clear All") {
                        ECMFramework.shared.clearAllCaches()
                        // Also clear MLX GPU cache if available
                        #if canImport(MLX)
                        MLX.GPU.clearCache()
                        #endif
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                
                ForEach(Array(cacheManager.caches.keys), id: \.self) { key in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(key)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if let tokenCount = cacheManager.cacheStats[key] {
                                Text("\(tokenCount) tokens")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(ECMFramework.shared.cacheStatus.preview(for: key))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
}
