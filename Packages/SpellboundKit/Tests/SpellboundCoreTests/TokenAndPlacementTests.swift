import Foundation
import CoreGraphics
import Testing
@testable import SpellboundCore

@Test func completedWordUsesUTF16Range() {
    let text = "🙂 This is neccessary "
    let token = CompletedToken.beforeCaret(in: text, caret: (text as NSString).length)
    #expect(token?.word == "neccessary")
    if let token { #expect((text as NSString).substring(with: token.range) == token.word) }
}

@Test(arguments: ["unfinished", "hello  ", "user_name ", "getUserName ", "https://example.com ", "a@b.com ", "file.swift ", "42things ", "`code` "])
func skipsIncompleteOrCodeTokens(_ text: String) {
    #expect(CompletedToken.beforeCaret(in: text, caret: (text as NSString).length) == nil)
}

@Test func pointerStaysAtWordWhenPanelClamped() {
    let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
    let word = CGRect(x: 35, y: 250, width: 80, height: 20)
    let placement = OverlayPlacement.anchored(to: word, size: CGSize(width: 570, height: 188), visibleScreen: screen)
    #expect(placement.isAbove)
    #expect(placement.frame.minX >= 8)
    #expect(abs(placement.frame.minX + placement.pointerX - word.midX) < 1)
    #expect(placement.frame.minY > word.maxY)
}

@Test func flipsBelowWordAtTopOfScreen() {
    let screen = CGRect(x: -1200, y: 100, width: 1200, height: 900)
    let word = CGRect(x: -600, y: 960, width: 80, height: 20)
    let placement = OverlayPlacement.anchored(to: word, size: CGSize(width: 570, height: 188), visibleScreen: screen)
    #expect(!placement.isAbove)
    #expect(placement.frame.maxY < word.minY)
    #expect(screen.contains(placement.frame))
}

@Test func catchesCompletedTypoWhileNextWordIsBeingTyped() {
    let before = "This is neccessary"
    let after = before + " and"
    let tokens = CompletedToken.newlyCompleted(in: after, after: before.utf16.count, caret: after.utf16.count)
    #expect(tokens.map(\.word) == ["neccessary"])
}

@Test func onlyChecksNewBoundaries() {
    let before = "An oldd word "
    let after = before + "next thing "
    let tokens = CompletedToken.newlyCompleted(in: after, after: before.utf16.count, caret: after.utf16.count)
    #expect(tokens.map(\.word) == ["next", "thing"])
}

@Test func completedBoundariesRespectUTF16Offsets() {
    let before = "🙂 neccessary"
    let after = before + " th"
    let tokens = CompletedToken.newlyCompleted(in: after, after: before.utf16.count, caret: after.utf16.count)
    #expect(tokens.count == 1)
    if let token = tokens.first { #expect((after as NSString).substring(with: token.range) == "neccessary") }
}
