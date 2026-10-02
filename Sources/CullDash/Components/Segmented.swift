import SwiftUI

/// A row of mutually exclusive choices, the selected one in the accent.
/// `count` adds a number after each title (e.g. "Picks 24"); 0 is shown too.
struct Segmented<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String
    var count: ((Value) -> Int)? = nil

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                let selected = option == selection
                Button {
                    selection = option
                } label: {
                    HStack(spacing: 6) {
                        Text(title(option))
                        if let count {
                            Text("\(count(option))")
                                .foregroundStyle(selected ? Theme.onAccent.opacity(0.7) : Theme.subtle)
                        }
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .foregroundStyle(selected ? Theme.onAccent : Theme.muted)
                    .background(selected ? Theme.accent : .clear, in: RoundedRectangle(cornerRadius: 6))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.controlRadius))
    }
}
