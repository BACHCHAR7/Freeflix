import SwiftUI

struct HeaderView: View {
    let categories: [Category]
    let selectedCategory: Category?
    let onSelectCategory: (Category?) -> Void
    
    var body: some View {
        HStack(spacing: 40) {
            Text("FREEFLIX")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.ffAccent)
            
            Spacer()
            
            HStack(spacing: 30) {
                Button {
                    onSelectCategory(nil)
                } label: {
                    Text("Accueil")
                        .font(.system(size: 22, weight: selectedCategory == nil ? .semibold : .regular))
                        .foregroundColor(selectedCategory == nil ? .white : .ffSecondary)
                }
                .buttonStyle(HeaderButtonStyle(isSelected: selectedCategory == nil))
                
                ForEach(categories) { category in
                    Button {
                        onSelectCategory(category)
                    } label: {
                        Text(category.name)
                            .font(.system(size: 22, weight: selectedCategory?.id == category.id ? .semibold : .regular))
                            .foregroundColor(selectedCategory?.id == category.id ? .white : .ffSecondary)
                    }
                    .buttonStyle(HeaderButtonStyle(isSelected: selectedCategory?.id == category.id))
                }
            }
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 30)
        .background(
            LinearGradient(
                colors: [.ffBackground, .ffBackground.opacity(0.8), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct HeaderButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.isFocused) var isFocused
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isFocused ? Color.ffAccent : (isSelected ? Color.white.opacity(0.1) : .clear))
            )
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

