## ADDED Requirements

### Requirement: Guided then recall practice
The challenge SHALL require one guided correct entry and two correct recall entries with the target hidden, using Unicode-normalized case-insensitive word comparison and ignoring surrounding whitespace.

#### Scenario: Successful exercise
- **WHEN** all three rounds are correctly submitted
- **THEN** the challenge completes and records a successful session

#### Scenario: Wrong answer
- **WHEN** a submitted spelling is incorrect
- **THEN** character feedback appears and the same round repeats without losing completed rounds

#### Scenario: Pasted answer
- **WHEN** the user pastes the target into the exercise
- **THEN** the round does not advance

### Requirement: Interrupt with an escape route
The app SHALL bring a single challenge forward for a current eligible candidate, provide Skip/Escape and Pause, and SHALL NOT claim guaranteed prevention of source-app submission.

#### Scenario: Skip
- **WHEN** the user presses Escape
- **THEN** the challenge closes without mastery credit and duplicate suppression begins

#### Scenario: Already submitted
- **WHEN** the source text was sent before detection completed
- **THEN** the app does not claim to undo or block that submission

### Requirement: Guarded correction handoff
The app SHALL offer source replacement only through a proven targeted-edit adapter after revalidating source identity, original token, range, context, permission, and app exclusion status.

#### Scenario: Safe replacement
- **WHEN** the original source remains valid and the user chooses Replace and return
- **THEN** only the original typo is replaced and surrounding text is preserved

#### Scenario: Stale source
- **WHEN** the source changes, disappears, or loses eligibility before replacement
- **THEN** no edit is attempted and an explicit Copy correction action is offered

#### Scenario: Unsupported editing
- **WHEN** observation works but targeted editing is unsupported
- **THEN** practice remains available and only explicit copy/manual correction is offered

### Requirement: Word-anchored typing strip
The challenge SHALL appear as a compact floating letter-slot strip anchored to the misspelled word's screen bounds. It SHALL track valid word movement and reflow, keep its pointer aligned when clamped at display edges, and move below the word when space above is insufficient. It SHALL dismiss when the source word is no longer valid or visible and SHALL NOT use the whole input bounds as a substitute for unavailable word coordinates.

#### Scenario: Word moves
- **WHEN** the source window moves or the visible source word reflows
- **THEN** the strip repositions to that word and its pointer remains word-aligned

#### Scenario: Word scrolls away
- **WHEN** the word leaves the editor's visible viewport
- **THEN** the strip dismisses without editing the source

#### Scenario: Word bounds unavailable
- **WHEN** the source control does not provide usable bounds for the word
- **THEN** the app reports unsupported positioning and does not display an input-anchored substitute

#### Scenario: Editing an answer
- **WHEN** the user moves the caret or selects letters in the practice input
- **THEN** the letter slots show the actual insertion point or selected range and all accepted word lengths remain visible
