import SwiftUI
import Combine

struct PopularDishesView: View {
    @StateObject private var viewModel = PopularDishesViewModel()
    @EnvironmentObject private var navigationManager: NavigationManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    UnifiedBackButton(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            navigationManager.goBack()
                        }
                    })
                    Spacer()
                }
                .padding(.horizontal)
                
                Text("Popular Dishes")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Choose a popular kind of dish that you want the recipe to be")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible(minimum: 80)),
                    GridItem(.flexible(minimum: 80)),
                    GridItem(.flexible(minimum: 80))
                ], spacing: 8) {
                    ForEach(viewModel.popularDishes, id: \.self) { dish in
                        PopularDishButton(
                            dish: dish,
                            isSelected: viewModel.selectedDish == dish,
                            action: { viewModel.selectDish(dish) }
                        )
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                Button(action: {
                    withAnimation(.easeInOut) {
                        navigationManager.navigate(to: .extraDetails(source: .popularDishes))
                    }
                }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Customize")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal)
                
                GroupBox(label: Text("Other Notes").bold()) {
                    TextEditor(text: $viewModel.additionalNotes)
                        .frame(height: 140) 
                        .padding()
                }
                
                Button(action: viewModel.generateRecipe) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("Generate Recipe")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .buttonStyle(PressableButtonStyle())
                .padding()
                .alert("No Recipe Selected", isPresented: $viewModel.showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Please select a popular dish before generating a recipe.")
                }
            }
            .padding(.bottom, 220) 
        }
        .scrollContentBackground(.visible)
        .contentMargins(.zero)
        .compatibleScrollDismissesKeyboard()
        .compatibleIgnoresKeyboardSafeArea()
        .swipeBackGesture(action: {
            withAnimation(.easeInOut) {
                navigationManager.goBack()
            }
        })
        .onAppear {
            viewModel.selectedDish = UserDefaults.standard.string(forKey: viewModel.savedDishKey)
            viewModel.additionalNotes = UserDefaults.standard.string(forKey: viewModel.savedNotesKey) ?? ""
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(.easeInOut(duration: 0.3), value: true)
    }
}

struct PopularDishButton: View {
    let dish: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(dish)
                .font(.footnote)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue.opacity(0.15) : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .blue : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

class PopularDishesViewModel: ObservableObject {
    @Published var selectedDish: String?
    @Published var additionalNotes = ""
    @Published var showError = false
    
    let savedDishKey = "SavedPopularDish"
    let savedNotesKey = "SavedPopularNotes"
    
    let popularDishes = [
        "Pizza", "Sushi", "Tacos", "Pasta", "Burger",
        "Pad Thai", "Paella", "Gravy", "Shawarma", "Pho",
        "Biryani", "Ramen", "Dumplings", "BBQ Ribs",
        "Fish and Chips", "Holiday Feast", "Festive Meal",
        "Traditional Feast", "Special Occasion", "Celebration Dish",
        "Custom Recipe (specify in Notes)"
    ]
    
    init() {
        selectedDish = UserDefaults.standard.string(forKey: savedDishKey)
        additionalNotes = UserDefaults.standard.string(forKey: savedNotesKey) ?? ""
    }
    
    func selectDish(_ dish: String) {
        if selectedDish == dish {
            selectedDish = nil
        } else {
            selectedDish = dish
        }
        UserDefaults.standard.set(selectedDish, forKey: savedDishKey)
    }
    
    func generateRecipe() {
        guard let dish = selectedDish else {
            showError = true
            return
        }
        
        Task {
            do {
                UserDefaults.standard.set(selectedDish, forKey: savedDishKey)
                UserDefaults.standard.set(additionalNotes, forKey: savedNotesKey)
                UserDefaults.standard.synchronize()
                
                NavigationManager.shared.navigate(to: .loading)
                
                var extraDetails = UserDefaults.standard.dictionary(forKey: "ExtraDetailsSelections") ?? [:]
                extraDetails["popular_dish"] = dish
                extraDetails["popular_notes"] = additionalNotes
                
                let prompt = createPrompt(dish: dish, extraDetails: extraDetails)
                let recipe = try await APIService.shared.generateRecipe(prompt: prompt)
                
                await MainActor.run {
                    NavigationManager.shared.navigate(to: .recipeDisplay(recipe))
                }
            } catch {
                await MainActor.run {
                    showError = true
                    NavigationManager.shared.navigateToRoot()
                }
            }
        }
    }
    
    private func createPrompt(dish: String, extraDetails: [String: Any]) -> String {
        var prompt = "Create a \(dish) recipe"
        
        if let popularNotes = extraDetails["popular_notes"] as? String, !popularNotes.isEmpty {
            prompt += "\n\nAdditional requirements:\n\(popularNotes)"
        } else if !additionalNotes.isEmpty {
            prompt += "\n\nAdditional requirements:\n\(additionalNotes)"
        }
        
        if let allergies = extraDetails["allergies"] as? [String], !allergies.isEmpty {
            prompt += "\n\nAvoid these allergies/restrictions:\n- " + allergies.joined(separator: "\n- ")
        }
        if let diet = extraDetails["diet_preferences"] as? [String], !diet.isEmpty {
            prompt += "\n\nDietary preferences:\n- " + diet.joined(separator: "\n- ")
        }
        if let equipment = extraDetails["equipment"] as? [String], !equipment.isEmpty {
            prompt += "\n\nAvailable equipment:\n- " + equipment.joined(separator: "\n- ")
        }
        if let timeConstraint = extraDetails["time_constraint"] as? String, !timeConstraint.isEmpty {
            prompt += "\n\nTime constraint: \(timeConstraint)"
        }
        if let servingSize = extraDetails["serving_size"] as? String, !servingSize.isEmpty {
            prompt += "\n\nServing size: \(servingSize)"
        }
        
        return prompt
    }
}

struct PopularDishesView_Previews: PreviewProvider {
    static var previews: some View {
        PopularDishesView()
            .environmentObject(NavigationManager())
    }
}

extension View {
    func popularDishesTransition() -> some View {
        self.transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
}
