import SwiftUI

/// Target letters disappear during recall, including from accessibility.
public struct LetterTiles: View {
    let target: String
    let answer: String
    let guided: Bool
    let showErrors: Bool
    let selection: Range<Int>

    public init(target: String, answer: String, guided: Bool, showErrors: Bool, selection: Range<Int>) {
        self.target = target; self.answer = answer; self.guided = guided; self.showErrors = showErrors
        self.selection = selection
    }

    public var body: some View {
        let count = max(target.count, answer.count)
        GeometryReader { geometry in
            let spacing: CGFloat = count > 14 ? 3 : 5
            let available = geometry.size.width - CGFloat(max(0, count - 1)) * spacing
            let width = min(31, max(10, available / CGFloat(max(1, count))))
            HStack(spacing: spacing) {
                ForEach(0..<count, id: \.self) { index in
                    cell(at: index, width: width, count: count)
                }
            }
        }
        .frame(height: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(guided ? "Spelling cue: \(target)" : "Spelling cue hidden")
        .accessibilityValue("\(answer.count) characters entered")
    }

    private func cell(at index: Int, width: CGFloat, count: Int) -> some View {
        let expected = Array(target)
        let typed = Array(answer)
        let entered = index < typed.count
        let selected = selection.contains(index)
        let current = selection.isEmpty && index == selection.lowerBound
        let wrong = entered && (index >= expected.count || String(typed[index]).lowercased() != String(expected[index]).lowercased())
        let character = entered ? String(typed[index]) : (guided && index < expected.count ? String(expected[index]) : " ")
        let foreground: Color = entered ? (showErrors && wrong ? .orange : .mint) : .white.opacity(0.5)
        let outline: Color = current || selected ? .mint : .white.opacity(0.13)
        return Text(character)
            .font(.system(size: min(23, width * 0.72), weight: .medium, design: .rounded))
            .foregroundStyle(foreground)
            .frame(width: width, height: 40)
            .background(selected ? Color.mint.opacity(0.2) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(outline, lineWidth: current || selected ? 1.5 : 1))
            .overlay(alignment: .trailing) {
                if selection.isEmpty && selection.lowerBound == count && index == count - 1 {
                    Rectangle().fill(Color.mint).frame(width: 2, height: 24).offset(x: 3)
                }
            }
    }
}
