#if os(macOS)
import AppKit

@MainActor
public enum SpellingService {
    public static func suggestions(for word: String) -> [String] {
        let checker = NSSpellChecker.shared
        let range = checker.checkSpelling(of: word, startingAt: 0, language: "en_US",
                                         wrap: false, inSpellDocumentWithTag: 0, wordCount: nil)
        guard range.location != NSNotFound else { return [] }
        return Array((checker.guesses(forWordRange: NSRange(location: 0, length: (word as NSString).length),
                                      in: word, language: "en_US", inSpellDocumentWithTag: 0) ?? [])
            .filter { !$0.contains(where: \.isWhitespace) && (3...24).contains($0.count) }.prefix(5))
    }
}
#endif
