import SwiftUI

struct InstructionsCarouselView: View {
    @State var index: Int = 0

    struct Step: Identifiable {
        let id: String

        init(_ image: String) {
            self.id = image
        }
    }

    var steps: [Step] {
        ["BTStep1", "BTStep2", "BTStep3"].map(Step.init)
    }

    var body: some View {
        CarouselView(spacing: 40, index: $index, items: steps) { step in
            StepCardView(image: step.id)
        }
        .padding(.top, 5)

        HStack {
            ForEach(steps.indices, id: \.self) { index in
                Circle()
                    .fill(index == self.index ? Color.primary : Color.secondary)
                    .frame(width: 7, height: 7)
                    .animation(.spring(), value: index == self.index)
            }
        }
        .padding(.top, 24)
    }
}

struct StepCardView: View {
    let image: String

    var body: some View {
        VStack {
            Spacer()
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(24)
                .shadow(color: .clear, radius: 0)
            Spacer()
        }
        .background(systemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .secondary, radius: 5, x: 0, y: 0)
    }
}
