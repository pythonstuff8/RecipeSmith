import SwiftUI
import Combine

enum NavigationDestination: Equatable {
    case home
    case loading
    case extraDetails(source: ExtraDetailsView.NavigationSource)
    case popularDishes
    case nutritionAnalytics(Recipe?)
    case recipeDisplay(Recipe)
    case savedRecipes
}

@MainActor
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    private var history: [NavigationDestination] = [.home]
    @Published private(set) var currentDestination: NavigationDestination = .home
    
    func updateRecipe(_ updatedRecipe: Recipe) {
        if case .recipeDisplay = currentDestination {
            withAnimation {
                currentDestination = .recipeDisplay(updatedRecipe)
            }
        }
    }
    
    func navigate(to destination: NavigationDestination) {
        withAnimation(.easeInOut(duration: 0.3)) {
            history.append(destination)
            currentDestination = destination
        }
    }
    
    var canGoBack: Bool { history.count > 1 }
    
    func goBack() {
        withAnimation(.easeInOut(duration: 0.3)) {
            guard canGoBack else { return }
            _ = history.popLast()
            currentDestination = history.last ?? .home
        }
    }
    
    func navigateToRoot() {
        history = [.home]
        currentDestination = .home
    }
}

struct SwipeBackModifier: ViewModifier {
    @EnvironmentObject private var navigationManager: NavigationManager
    let customAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        content.highPriorityGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    let isLeftEdge = value.startLocation.x <= 30
                    let isHorizontal = abs(value.translation.height) < 50
                    let isRightSwipe = value.translation.width > 80
                    if isLeftEdge && isHorizontal && isRightSwipe {
                        if let action = customAction {
                            action()
                        } else {
                            navigationManager.goBack()
                        }
                    }
                }
        )
    }
}

struct ToolbarBackModifier: ViewModifier {
    @EnvironmentObject private var navigationManager: NavigationManager
    var title: String?
    let customAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { (customAction ?? { navigationManager.goBack() })() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(title ?? "Back")
                    }
                }
            }
        }
    }
}

extension View {
    func swipeBackGesture() -> some View {
        modifier(SwipeBackModifier(customAction: nil))
    }
    
    func swipeBackGesture(action: @escaping () -> Void) -> some View {
        modifier(SwipeBackModifier(customAction: action))
    }
    
    func toolbarBackButton(_ title: String? = nil) -> some View {
        modifier(ToolbarBackModifier(title: title, customAction: nil))
    }
    
    func toolbarBackButton(_ title: String? = nil, action: @escaping () -> Void) -> some View {
        modifier(ToolbarBackModifier(title: title, customAction: action))
    }
}

struct UnifiedBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .imageScale(.large)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct PressableButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    var pressedOpacity: Double = 0.8
    
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

