// MARK: - Usage Example: How to use ECM Framework in your app

import SwiftUI
import MLX
import MLXLLM
import ECMFramework

// MARK: - MLX Context Adapter (Required for MLX integration)

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

// MARK: - Your MLX Service

class YourMLXService: ObservableObject {
    @Published var output = ""
    @Published var isLoading = false
    private var modelContainer: ModelContainer?
    
    func loadModel() async {
        // Your existing model loading code...
    }
    
    func processMessageWithECM(_ message: String) async {
        guard let container = modelContainer else {
            output = "Model not loaded"
            return
        }
        
        do {
            let result = try await container.perform { context in
                // ✨ Create MLX adapter for ECM Framework
                let ecmContext = MLXContextAdapter(context)
                
                // ✨ Use ECM Framework to process the message
                let ecmResult = try await ECMFramework.shared.processMessage(message, context: ecmContext)
                
                // If there are only cache operations with no query, return confirmation
                guard ecmResult.hasCleanInput else {
                    return "✅ Cache operation completed successfully."
                }
                
                // Use the assembled prompt for generation
                let finalPrompt = ecmResult.finalPrompt
                let userInput = UserInput(prompt: finalPrompt)
                let lmInput = try await context.processor.prepare(input: userInput)
                
                // Generate response using MLX
                var generatedText = ""
                
                let _ = try MLXLMCommon.generate(
                    input: lmInput,
                    parameters: GenerateParameters(
                        maxTokens: 150,
                        temperature: 0.1,
                        topP: 0.9
                    ),
                    context: context
                ) { tokens in
                    let fullText = context.tokenizer.decode(tokens: tokens)
                    generatedText = fullText
                    
                    Task { @MainActor in
                        self.output = generatedText
                    }
                    
                    // Stop at natural points
                    if fullText.contains(".") && fullText.count > 50 {
                        return .stop
                    }
                    
                    return .more
                }
                
                return generatedText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            output = result
            
        } catch {
            output = "Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - SwiftUI View Example

struct ECMExampleView: View {
    @StateObject private var mlxService = YourMLXService()
    @State private var inputText = ""
    
    var body: some View {
        VStack {
            // Cache Status Display
            ECMCacheStatusView()
            
            // Output
            Text(mlxService.output)
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(8)
            
            // Input
            TextField("Enter cache directive or question...", text: $inputText)
                .textFieldStyle(.roundedBorder)
            
            Button("Send") {
                Task {
                    await mlxService.processMessageWithECM(inputText)
                    inputText = ""
                }
            }
            .disabled(inputText.isEmpty)
        }
        .padding()
        .task {
            await mlxService.loadModel()
        }
    }
}

// MARK: - Reusable Cache Status View

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
                        // Also clear MLX GPU cache
                        MLX.GPU.clearCache()
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

// MARK: - Example Cache Directives

/*
 Example usage patterns:
 
 1. Cache a document:
 "[System Cache: legal_doc] This comprehensive legal agreement..."
 
 2. Reference cached content:
 "Based on cache reference: legal_doc, what is the contract duration?"
 
 3. Clean specific cache:
 "[System Clean Cache: legal_doc]"
 
 4. Clean all caches:
 "[System Clean Cache]"
 
 5. Multiple operations:
 "[System Cache: doc1] Content 1... [System Cache: doc2] Content 2..."
 
 6. Scroll behavior in SwiftUI:
 // Instead of separate function, use inline scroll:
 Button("Example") {
     inputText = "..."
     DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
         withAnimation(.easeInOut(duration: 0.3)) {
             proxy.scrollTo("targetID", anchor: .bottom)
         }
     }
 }
 */