import SwiftUI
import Combine

struct IngredientSearchView: View {
    @StateObject private var viewModel = IngredientSearchViewModel()
    @Binding var selectedIngredient: Ingredient
    @Environment(\.dismiss) private var dismiss
    @State private var customIngredientName = ""
    @State private var showingCustomIngredientSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search ingredients...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .submitLabel(.search)
                        .onSubmit { viewModel.searchNow() }
                    
                    Button(action: { viewModel.searchNow() }) {
                        Image(systemName: "arrow.forward.circle.fill")
                            .foregroundColor(.blue)
                            .imageScale(.large)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .padding()
                
                Button(action: { showingCustomIngredientSheet = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Can't find your ingredient? Add custom")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    List {
                        ForEach(viewModel.searchResults, id: \.id) { ingredient in
                            Button {
                                selectedIngredient.detail = ingredient
                                selectedIngredient.text = ingredient.name
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ingredient.name)
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 8) {
                                        Label("\(Int(ingredient.calories))", systemImage: "flame.fill")
                                        Label("\(Int(ingredient.protein))g", systemImage: "p.circle.fill")
                                        Label("\(Int(ingredient.carbs))g", systemImage: "c.circle.fill")
                                        Label("\(Int(ingredient.fat))g", systemImage: "f.circle.fill")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCustomIngredientSheet) {
                CustomIngredientSheet(
                    selectedIngredient: $selectedIngredient,
                    dismiss: { dismiss() }   
                )
            }
        }
    }
}

struct CustomIngredientSheet: View {
    @Binding var selectedIngredient: Ingredient
    @Environment(\.dismiss) private var dismissSheet
    var dismiss: () -> Void  
    
    @State private var name = ""
    @State private var calories: Double = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var includeNutrition = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Ingredient Name")) {
                    TextField("Name", text: $name)
                }
                
                Section {
                    Toggle("Add Nutritional Information", isOn: $includeNutrition)
                }
                
                if includeNutrition {
                    Section(header: Text("Nutrition Per 100g")) {
                        HStack {
                            Text("Calories")
                            Spacer()
                            TextField("0", value: $calories, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Protein (g)")
                            Spacer()
                            TextField("0", value: $protein, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Carbs (g)")
                            Spacer()
                            TextField("0", value: $carbs, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Fat (g)")
                            Spacer()
                            TextField("0", value: $fat, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .navigationTitle("Add Custom Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismissSheet() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if includeNutrition {
                            let detail = IngredientDetail(
                                id: Int(Date().timeIntervalSince1970),
                                name: name,
                                calories: calories,
                                protein: protein,
                                carbs: carbs,
                                fat: fat,
                                servingSize: 100,
                                servingSizeUnit: "g"
                            )
                            selectedIngredient.detail = detail
                            selectedIngredient.text = name
                        } else {
                            selectedIngredient.text = name
                            selectedIngredient.detail = nil
                        }
                        dismissSheet()  
                        dismiss()      
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct NutrientLabel: View {
    let name: String
    let value: Double
    
    var body: some View {
        Text("\(name): \(String(format: "%.1f", value))")
    }
}

class IngredientSearchViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [IngredientDetail] = []
    @Published var isLoading = false
    
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                guard let self = self else { return }
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Task { @MainActor in
                        self.searchResults = []
                        self.isLoading = false
                    }
                    return
                }
                Task {
                    await self.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    func searchNow() {
        searchTask?.cancel()
        searchTask = Task {
            await performSearch(query: searchQuery)
        }
    }
    
    private func performSearch(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await MainActor.run {
                self.searchResults = []
                self.isLoading = false
            }
            return
        }

        await MainActor.run { self.isLoading = true }

        do {
            let results = try await IngredientService.shared.searchIngredients(query: trimmed)
            await MainActor.run {
                self.searchResults = results
                self.isLoading = false
            }
        } catch {
            print("Search error: \(error)")
            await MainActor.run {
                self.searchResults = []
                self.isLoading = false
            }
        }
    }
    
    deinit {
        searchTask?.cancel()
    }
}
