import SwiftUI
import Combine
import Foundation
@main
struct RecipeSmithApp: App {
    @StateObject private var navigationManager = NavigationManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(navigationManager)
                .dismissKeyboard()
        }
    }
}

struct RootView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    
    var body: some View {
        ZStack {
            switch navigationManager.currentDestination {
            case .home, .savedRecipes:
                MainTabView()
                    .transition(.opacity)
            case .extraDetails(let source):
                ExtraDetailsView(source: source)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .popularDishes:
                PopularDishesView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .recipeDisplay(let recipe):
                RecipeDisplayView(recipe: recipe)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            case .loading:
                LoadingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: navigationManager.currentDestination)
    }
}
