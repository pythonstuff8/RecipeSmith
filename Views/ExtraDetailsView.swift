import SwiftUI
import Combine   
import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct UserSelections: Codable {
    var allergies: [String] = []
    var dietPreferences: [String] = []
    var mealTypes: [String] = []
    var cuisineTypes: [String] = []
    var equipment: [String] = ExtraDetailsConstants.equipmentTypes 
    var servingSize: String = "4"
    var notes: String = ""
    var timeConstraint: String = "No Time Limit" 
    var caloriesMin: Int = -1
    var caloriesMax: Int = -1
    var carbsMin: Int = -1
    var carbsMax: Int = -1
    var proteinMin: Int = -1
    var proteinMax: Int = -1
    var fatMin: Int = -1
    var fatMax: Int = -1
}

class ExtraDetailsViewModel: ObservableObject {
    @Published var userSelections: UserSelections
    
    struct Constants {
        static let allergies = [
            "Dairy", "Eggs", "Peanuts", "Soy", "Wheat / Gluten",
            "Fish", "Shellfish", "Sesame", "Corn", "Sulfites", "Tree Nuts"
        ]
        
        static let dietPreferences = [
            "Vegetarian", "Vegan", "Pescatarian", "Gluten-Free",
            "Lactose-Free", "Dairy-Free", "Nut-Free", "Soy-Free",
            "Low-Carb / Keto", "Low-FODMAP", "Diabetic-Friendly",
            "Paleo", "Halal", "Kosher", "Low-Sodium", "High-Protein"
        ]
        
        static let timeOptions = [
            "No Time Limit",
            "Under 10 min",
            "Under 20 min", 
            "Under 30 min",
            "Under 1hr"
        ]
        
        static let mealTypes = [
            "Breakfast", "Lunch", "Dinner", "Snack", "Dessert",
            "Appetizer", "Side Dish", "Salad", "Soup", "Beverage",
            "Condiment", "Smoothie"
        ]
        
        static let cuisineTypes = [
            "American", "Italian", "Mexican", "Chinese", "Indian",
            "Japanese", "Mediterranean", "French", "Spanish",
            "Thai", "Brazilian", "Vietnamese"
        ]
        
        static let equipment = [
            "Stove top", "Oven", "Microwave", "Blender", "Air Fryer",
            "Instant Pot", "Toaster", "No-Cook", "Grill", "Food Processor"
        ]
    }
    
    var allergies: [String] { Constants.allergies }
    var dietPreferences: [String] { Constants.dietPreferences }
    var timeOptions: [String] { Constants.timeOptions }
    var mealTypes: [String] { Constants.mealTypes }
    var cuisineTypes: [String] { Constants.cuisineTypes }
    var equipment: [String] { Constants.equipment }
    
    init() {
        self.userSelections = UserSelections()
        self.userSelections.equipment = ExtraDetailsConstants.equipmentTypes 
        
        if let savedData = UserDefaults.standard.dictionary(forKey: "ExtraDetailsSelections") {
            loadSavedSelections(from: savedData)
        } else {
            
            userSelections.timeConstraint = "No Time Limit"
            userSelections.caloriesMin = -1 
            userSelections.caloriesMax = -1
        }
    }
    
    private func loadSavedSelections(from savedData: [String: Any]) {
        var loadedSelections = UserSelections()
        
        loadedSelections.allergies = savedData["allergies"] as? [String] ?? []
        loadedSelections.dietPreferences = savedData["diet_preferences"] as? [String] ?? []
        loadedSelections.mealTypes = savedData["meal_types"] as? [String] ?? []
        loadedSelections.cuisineTypes = savedData["cuisine_types"] as? [String] ?? []
        loadedSelections.equipment = savedData["equipment"] as? [String] ?? []
        loadedSelections.servingSize = savedData["serving_size"] as? String ?? "4"
        loadedSelections.notes = savedData["notes"] as? String ?? ""
        loadedSelections.timeConstraint = savedData["time_constraint"] as? String ?? "No Time Limit"
        loadedSelections.caloriesMin = savedData["calories_min"] as? Int ?? 0
        loadedSelections.caloriesMax = savedData["calories_max"] as? Int ?? 0
        loadedSelections.carbsMin = savedData["carbs_min"] as? Int ?? 0
        loadedSelections.carbsMax = savedData["carbs_max"] as? Int ?? 0
        loadedSelections.proteinMin = savedData["protein_min"] as? Int ?? 0
        loadedSelections.proteinMax = savedData["protein_max"] as? Int ?? 0
        loadedSelections.fatMin = savedData["fat_min"] as? Int ?? 0
        loadedSelections.fatMax = savedData["fat_max"] as? Int ?? 0
        
        self.userSelections = loadedSelections
    }
    
    func saveSelections() {
        let selections: [String: Any] = [
            "allergies": userSelections.allergies,
            "diet_preferences": userSelections.dietPreferences,
            "meal_types": userSelections.mealTypes,
            "cuisine_types": userSelections.cuisineTypes,
            "equipment": userSelections.equipment,
            "serving_size": userSelections.servingSize,
            "notes": userSelections.notes,
            "time_constraint": userSelections.timeConstraint,
            "calories_min": userSelections.caloriesMin,
            "calories_max": userSelections.caloriesMax,
            "protein_min": userSelections.proteinMin,
            "protein_max": userSelections.proteinMax,
            "carbs_min": userSelections.carbsMin,
            "carbs_max": userSelections.carbsMax,
            "fat_min": userSelections.fatMin,
            "fat_max": userSelections.fatMax
        ]
        
        UserDefaults.standard.set(selections, forKey: "ExtraDetailsSelections")
        UserDefaults.standard.synchronize()
    }
    
    func toggleSelection(item: String, in array: inout [String]) {
        if array.contains(item) {
            array.removeAll { $0 == item }
        } else {
            array.append(item)
        }
    }
    
    func toggleAllergy(_ allergy: String) {
        toggleSelection(item: allergy, in: &userSelections.allergies)
    }
    
    func toggleDietPreference(_ preference: String) {
        toggleSelection(item: preference, in: &userSelections.dietPreferences)
    }
    
    func toggleMealType(_ type: String) {
        toggleSelection(item: type, in: &userSelections.mealTypes)
    }
    
    func toggleCuisineType(_ type: String) {
        toggleSelection(item: type, in: &userSelections.cuisineTypes)
    }
    
    func toggleEquipment(_ item: String) {
        toggleSelection(item: item, in: &userSelections.equipment)
    }
}

struct ExtraDetailsView: View {
    @StateObject private var viewModel = ExtraDetailsViewModel()
    @EnvironmentObject private var navigationManager: NavigationManager
    @State private var showingSaveAlert = false
    let source: NavigationSource
    
    enum NavigationSource {
        case home
        case popularDishes
        case savedRecipes
    }
    
    private let allergies = ["Dairy", "Eggs", "Peanuts", "Soy", "Wheat / Gluten",
                           "Fish", "Shellfish", "Sesame", "Corn", "Sulfites", "Tree Nuts"]
    
    private let dietaryPreferences = ["Vegetarian", "Vegan", "Pescatarian", "Gluten-Free",
                                    "Lactose-Free", "Dairy-Free", "Nut-Free", "Soy-Free",
                                    "Low-Carb / Keto", "Low-FODMAP", "Diabetic-Friendly",
                                    "Paleo", "Halal", "Kosher", "Low-Sodium", "High-Protein"]
    
    private let timeConstraints = ["Under 10 min", "Under 20 min", "Under 30 min",
                                 "Under 1hr", "No Time Limit"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    Group {
                        SectionView(title: "Dietary Restrictions/Allergies") {
                            ChipGridView(items: allergies,
                                       selectedItems: $viewModel.userSelections.allergies)
                        }
                        
                        SectionView(title: "Diet Preferences") {
                            ChipGridView(items: dietaryPreferences,
                                       selectedItems: $viewModel.userSelections.dietPreferences)
                        }
                    }
                    
                    Group {
                        SectionView(title: "Meal Type") {
                            ChipGridView(items: ExtraDetailsConstants.mealTypes,
                                       selectedItems: $viewModel.userSelections.mealTypes,
                                       singleSelection: true)
                        }
                        
                        SectionView(title: "Cuisine Type") {
                            ChipGridView(items: ExtraDetailsConstants.cuisineTypes,
                                       selectedItems: $viewModel.userSelections.cuisineTypes,
                                       singleSelection: true)
                        }
                    }
                    
                    SectionView(title: "Equipment Available") {
                        ChipGridView(items: ExtraDetailsConstants.equipmentTypes,
                                   selectedItems: $viewModel.userSelections.equipment)
                    }
                    
                    Group {
                        TimeConstraintView(selection: $viewModel.userSelections.timeConstraint,
                                         options: ExtraDetailsConstants.timeOptions)
                            .padding(.vertical)
                        
                        ServingSizeView(servingSize: $viewModel.userSelections.servingSize)
                    }
                    
                    NutritionalInputsView(userSelections: $viewModel.userSelections)
                        .padding(.vertical)
                    
                    NotesView(notes: $viewModel.userSelections.notes)
                    
                    Button("Save Changes") {
                        viewModel.saveSelections()
                        withAnimation(.easeInOut) {
                            switch source {
                            case .home:
                                navigationManager.navigateToRoot()
                            case .popularDishes:
                                navigationManager.goBack()
                            case .savedRecipes:
                                navigationManager.navigate(to: .savedRecipes)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .buttonStyle(PressableButtonStyle())
                    .padding(.vertical, 30)
             }
            .padding()
            .padding(.bottom, 220) 
         }
         .scrollContentBackground(.visible)
         .contentMargins(.zero)
         .compatibleScrollDismissesKeyboard()
         .compatibleIgnoresKeyboardSafeArea()
         .navigationTitle("Customize Recipe")
         .navigationBarTitleDisplayMode(.inline)
         .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                UnifiedBackButton(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSaveAlert = true
                    }
                })
            }
         }
         .alert("Save Changes?", isPresented: $showingSaveAlert) {
            Button("Discard", role: .destructive) {
                withAnimation(.easeInOut) {
                    navigationManager.goBack()
                }
            }
            Button("Save", role: .none) {
                viewModel.saveSelections()
                withAnimation(.easeInOut) {
                    navigationManager.goBack()
                }
            }
            Button("Cancel", role: .cancel) {}
         } message: {
            Text("Do you want to save your changes before leaving?")
         }
        }
        .swipeBackGesture(action: { 
            withAnimation(.easeInOut) {
                showingSaveAlert = true
            }
        })
        .navigationViewStyle(.stack)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
}

struct HeaderView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("Extra Details")
                .font(.title)
                .bold()
            Text("Add your extra details and preferences")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
            content
                .padding(.top, 6)
        }
    }
}

struct ChipView: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .animation(.easeInOut, value: isSelected)
                .shadow(radius: isSelected ? 2 : 0)
        }
    }
}

struct ScrollDismissesKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            content.scrollDismissesKeyboard(.interactively)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

extension View {
    func compatibleScrollDismissesKeyboard() -> some View {
        modifier(ScrollDismissesKeyboardModifier())
    }
}

struct IgnoreKeyboardSafeAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 15.0, *) {
            content.ignoresSafeArea(.keyboard)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

extension View {
    func compatibleIgnoresKeyboardSafeArea() -> some View {
        modifier(IgnoreKeyboardSafeAreaModifier())
    }
}

struct ChipGridView: View {
    let items: [String]
    @Binding var selectedItems: [String]
    var singleSelection: Bool = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items, id: \.self) { item in
                ChipView(
                    title: item,
                    isSelected: selectedItems.contains(item)
                ) {
                    if singleSelection {
                        selectedItems = [item]
                    } else {
                        if selectedItems.contains(item) {
                            selectedItems.removeAll { $0 == item }
                        } else {
                            selectedItems.append(item)
                        }
                    }
                }
                .contentShape(Rectangle())  
                .allowsHitTesting(true) 
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

struct TimeConstraintView: View {
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Time Constraint")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(options, id: \.self) { option in
                        Button(action: { selection = option }) {
                            Text(option)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selection == option ?
                                        Color.blue : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(
                                    selection == option ? .white : .primary
                                )
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
struct ServingSizeView: View {
    @Binding var servingSize: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Serving Size")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
            
            HStack {
                Spacer()
                TextField("Enter serving size (1-10)", text: $servingSize)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .frame(width: 120)
                    .keyboardType(.numberPad)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                             to: nil, 
                                                             from: nil, 
                                                             for: nil)
                            }
                        }
                    }
                Spacer()
            }
        }
    }
}

struct NutritionalInputsView: View {
    @Binding var userSelections: UserSelections
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Nutritional Information")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
            
            NutritionalRangeInput(
                title: "Calories",
                minValue: $userSelections.caloriesMin,
                maxValue: $userSelections.caloriesMax
            )
            
            NutritionalRangeInput(
                title: "Carbs (g)",
                minValue: $userSelections.carbsMin,
                maxValue: $userSelections.carbsMax
            )
            
            NutritionalRangeInput(
                title: "Protein (g)",
                minValue: $userSelections.proteinMin,
                maxValue: $userSelections.proteinMax
            )
            
            NutritionalRangeInput(
                title: "Fat (g)",
                minValue: $userSelections.fatMin,
                maxValue: $userSelections.fatMax
            )
        }
    }
}
struct NutritionalRangeInput: View {
    let title: String
    @Binding var minValue: Int
    @Binding var maxValue: Int
    @State private var isMinNA: Bool = true
    @State private var isMaxNA: Bool = true
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
            
            HStack {
                if isMinNA {
                    Button("N/A") {
                        isMinNA = false
                        minValue = 0
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.secondary)
                } else {
                    TextField("Min", value: $minValue, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                                 to: nil, 
                                                                 from: nil, 
                                                                 for: nil)
                                }
                            }
                        }
                }
                
                Text("-")
                
                if isMaxNA {
                    Button("N/A") {
                        isMaxNA = false
                        maxValue = 0
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.secondary)
                } else {
                    TextField("Max", value: $maxValue, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                                 to: nil, 
                                                                 from: nil, 
                                                                 for: nil)
                                }
                            }
                        }
                }
            }
            .onAppear {
                isMinNA = minValue == -1
                isMaxNA = maxValue == -1
            }
            .onChange(of: minValue) { newValue in
                if newValue == -1 {
                    isMinNA = true
                }
            }
            .onChange(of: maxValue) { newValue in
                if newValue == -1 {
                    isMaxNA = true
                }
            }
            
            if !isMinNA || !isMaxNA {
                Button("Reset to N/A") {
                    minValue = -1
                    maxValue = -1
                    isMinNA = true
                    isMaxNA = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
}

struct NotesView: View {
    @Binding var notes: String
    
    var body: some View {
        VStack(alignment: .center) {
            Text("Additional Notes")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            TextEditor(text: $notes)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2))
                )
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), 
                                                         to: nil, 
                                                         from: nil, 
                                                         for: nil)
                        }
                    }
                }
        }
    }
}

struct ExtraDetailsConstants {
    static let mealTypes = [
        "Breakfast", "Lunch", "Dinner", "Snack", "Dessert",
        "Appetizer", "Side Dish", "Salad", "Soup", "Beverage",
        "Condiment", "Smoothie"
    ]
    
    static let cuisineTypes = [
        "American", "Italian", "Mexican", "Chinese", "Indian",
        "Japanese", "Mediterranean", "French", "Spanish", "Thai",
        "Brazilian", "Vietnamese"
    ]
    
    static let equipmentTypes = [
        "Stove top", "Oven", "Microwave", "Blender", "Air Fryer",
        "Instant Pot", "Toaster", "No-Cook", "Grill", "Food Processor"
    ]
    
    static let timeOptions = [
        "No Time Limit",
        "Under 10 min",
        "Under 20 min", 
        "Under 30 min",
        "Under 1hr"
    ]
}

struct ExtraDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ExtraDetailsView(source: .home)
            .environmentObject(NavigationManager())
    }
}

struct DismissKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        #else
        content
        #endif
    }
}

extension View {
    func dismissKeyboard() -> some View {
        modifier(DismissKeyboardModifier())
    }
}
