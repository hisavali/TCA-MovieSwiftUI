import ComposableArchitecture
import SwiftUI

public struct PopularityBadge : View {
    let score: Int
    @State var didAppear: Bool = false

    private var scoreColor: Color {
        get {
            if score < 40 {
                return .red
            } else if score < 60 {
                return .orange
            } else if score < 75 {
                return .yellow
            }
            return .green
        }
    }

    var overlay: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: self.didAppear ? CGFloat(self.score) / 100 : 0)
                .stroke(style: .init(lineWidth: 2, dash: [1]))
                .foregroundColor(self.scoreColor)
                .animation(.interpolatingSpring(
                    stiffness: 60,
                    damping: 10
                ).delay(0.2))
                .shadow(color: self.scoreColor, radius: 3)
        }
    }

    public var body: some View {
        ZStack {
            Circle()
                .foregroundColor(.clear)
                .frame(width: 40)
                .overlay(self.overlay)
            Text("\(self.score)%")
                .font(.system(size: 10))
                .foregroundColor(.black)
        }
        .onAppear {
            self.didAppear = true
        }
    }
}

struct PopularityBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PopularityBadge(score: 10)
            PopularityBadge(score: 30)
            PopularityBadge(score: 50)
            PopularityBadge(score: 80)
        }
    }
}
