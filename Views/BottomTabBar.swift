import SwiftUI
import Combine
import Foundation
struct BottomTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject private var navigationManager: NavigationManager
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                title: "Home",
                icon: "house.fill",
                isSelected: selectedTab == 0
            ) {
                withAnimation {
                    selectedTab = 0
                    navigationManager.navigate(to: .home)
                }
            }
            
            TabBarButton(
                title: "Saved",
                icon: "bookmark.fill",
                isSelected: selectedTab == 1
            ) {
                withAnimation {
                    selectedTab = 1
                    navigationManager.navigate(to: .savedRecipes)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.gray.opacity(0.3)),
            alignment: .top
        )
    }
}

struct TabBarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .imageScale(.large)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? .blue : .gray)
            .animation(.easeInOut, value: isSelected)
        }
    }
}
