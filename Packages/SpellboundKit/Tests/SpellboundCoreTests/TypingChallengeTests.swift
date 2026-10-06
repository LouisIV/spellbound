import Testing
@testable import SpellboundCore

@Test func guidedThenTwoRecallRounds() throws {
    var challenge = try TypingChallenge(word: "necessary")
    #expect(challenge.phase == .guided)
    #expect(challenge.submit("necessary") == .correct)
    #expect(challenge.phase == .recall(1))
    #expect(challenge.submit("necessary") == .correct)
    #expect(challenge.phase == .recall(2))
    #expect(challenge.submit("necessary") == .correct)
    #expect(challenge.phase == .completed)
    #expect(challenge.submit("necessary") == .inactive)
}

@Test func mistakesRepeatCurrentRound() throws {
    var challenge = try TypingChallenge(word: "separate")
    _ = challenge.submit("separate")
    #expect(challenge.submit("seperate") == .incorrect)
    #expect(challenge.phase == .recall(1))
    #expect(challenge.mistakes == 1)
}

@Test func pastedAnswersNeverAdvance() throws {
    var challenge = try TypingChallenge(word: "receive")
    #expect(challenge.submit("receive", pasted: true) == .pasteRejected)
    #expect(challenge.phase == .guided)
    #expect(challenge.mistakes == 0)
}

@Test func skipCannotAwardCompletion() throws {
    var challenge = try TypingChallenge(word: "receive")
    challenge.skip()
    #expect(challenge.phase == .skipped)
    #expect(challenge.submit("receive") == .inactive)
}

@Test func normalizationPreservesAccents() throws {
    var challenge = try TypingChallenge(word: "café")
    #expect(challenge.submit(" CAFE\u{301}\n") == .correct)
    #expect(challenge.submit("cafe") == .incorrect)
}

@Test(arguments: ["", "  ", "two words", "two\nwords"])
func rejectsInvalidTargets(_ word: String) {
    #expect(throws: TypingChallenge.ValidationError.self) { try TypingChallenge(word: word) }
}

@Test func completedChallengeCannotBeSkipped() throws {
    var challenge = try TypingChallenge(word: "receive")
    for _ in 0..<3 { _ = challenge.submit("receive") }
    challenge.skip()
    #expect(challenge.phase == .completed)
}

@Test(arguments: ["AXSecureTextField", "AXUnknown"])
func excludedSubroles(_ subrole: String) {
    #expect(!ObservationEligibility.permitsRead(permissionGranted: true, appExcluded: false,
        monitoringActive: true, role: "AXTextField", subrole: subrole))
}

@Test func allEligibilityConditionsRequired() {
    for permission in [false, true] {
        for excluded in [false, true] {
            for active in [false, true] {
                #expect(ObservationEligibility.permitsRead(permissionGranted: permission,
                    appExcluded: excluded, monitoringActive: active, role: "AXTextArea", subrole: nil)
                    == (permission && !excluded && active))
            }
        }
    }
    #expect(!ObservationEligibility.permitsRead(permissionGranted: true, appExcluded: false,
        monitoringActive: true, role: "AXWebArea", subrole: nil))
}
