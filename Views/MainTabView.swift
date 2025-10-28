import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var navigationManager: NavigationManager
    @State private var selectedTab: Int = 0   

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(0)
                SavedRecipesView()
                    .tag(1)
                NutritionAnalyticsView(initialRecipe: nil)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            BottomTabBar(selectedTab: $selectedTab)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView().environmentObject(NavigationManager.shared)
    }
}
