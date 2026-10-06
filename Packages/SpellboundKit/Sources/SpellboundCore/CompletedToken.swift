import Foundation

public struct CompletedToken: Equatable, Sendable {
    public let word: String
    public let range: NSRange

    /// Finds every newly completed word even when typing has continued into the next word.
    public static func newlyCompleted(in text: String, after offset: Int, caret: Int) -> [CompletedToken] {
        guard offset >= 0, caret <= (text as NSString).length, offset < caret else { return [] }
        var boundary = 0
        var result: [CompletedToken] = []
        for character in text {
            boundary += String(character).utf16.count
            guard boundary > offset else { continue }
            if boundary > caret { break }
            if character.isWhitespace || ".,!?;:".contains(character),
               let token = beforeCaret(in: text, caret: boundary) { result.append(token) }
        }
        return result
    }

    /// UTF-16 offsets match NSTextView and the Accessibility text APIs.
    public static func beforeCaret(in text: String, caret: Int) -> CompletedToken? {
        let ns = text as NSString
        guard caret > 0, caret <= ns.length else { return nil }
        let prefix = ns.substring(to: caret)
        guard let last = prefix.last, last.isWhitespace || ".,!?;:".contains(last) else { return nil }
        // Consume exactly one completed boundary; avoid reopening old words on blank lines.
        let trimmed = String(prefix.dropLast())
        guard let end = trimmed.last, end.isLetter || end == "'" else { return nil }
        let raw = trimmed.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? ""
        guard !raw.contains("@"), !raw.contains("/"), !raw.contains("\\"),
              !raw.contains("."), !raw.contains("_"), !raw.contains("`"),
              !raw.contains(":"), !raw.contains("=") else { return nil }
        let word = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\"'([{“”"))
        guard (3...24).contains(word.count),
              word.unicodeScalars.allSatisfy({ CharacterSet.letters.contains($0) || $0 == "'" }),
              !word.dropFirst().contains(where: \.isUppercase),
              word.rangeOfCharacter(from: .decimalDigits) == nil else { return nil }
        // Restrict this prototype to English/Latin input. Other composition needs an adapter.
        guard word.unicodeScalars.allSatisfy({ $0.value < 128 }) else { return nil }
        let length = (word as NSString).length
        let endOffset = (trimmed as NSString).length
        return CompletedToken(word: word, range: NSRange(location: endOffset - length, length: length))
    }
}
