import Foundation

/// Platform-independent exercise state. Input adapters must label pasted submissions.
public struct TypingChallenge: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        case guided
        case recall(Int)
        case completed
        case skipped
    }

    public enum Submission: Equatable, Sendable {
        case correct
        case incorrect
        case pasteRejected
        case inactive
    }

    public enum ValidationError: Error { case invalidWord }

    public let word: String
    public private(set) var phase: Phase = .guided
    public private(set) var mistakes = 0

    public init(word: String) throws {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(where: \.isWhitespace) else {
            throw ValidationError.invalidWord
        }
        self.word = trimmed.precomposedStringWithCanonicalMapping
    }

    public var isActive: Bool {
        switch phase {
        case .guided, .recall: true
        case .completed, .skipped: false
        }
    }

    public mutating func submit(_ answer: String, pasted: Bool = false) -> Submission {
        guard isActive else { return .inactive }
        guard !pasted else { return .pasteRejected }
        guard Self.normalized(answer) == Self.normalized(word) else {
            mistakes += 1
            return .incorrect
        }
        switch phase {
        case .guided: phase = .recall(1)
        case .recall(1): phase = .recall(2)
        case .recall: phase = .completed
        case .completed, .skipped: break
        }
        return .correct
    }

    public mutating func skip() {
        guard isActive else { return }
        phase = .skipped
    }

    private static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .precomposedStringWithCanonicalMapping
            .lowercased(with: Locale(identifier: "en_US_POSIX"))
    }
}
