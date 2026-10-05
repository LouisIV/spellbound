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
The app SHALL offer source replacement only through a proven targeted-edit adapter after revalidating source identity, original token, range, context, permission, and app enablement.

#### Scenario: Safe replacement
- **WHEN** the original source remains valid and the user chooses Replace and return
- **THEN** only the original typo is replaced and surrounding text is preserved

#### Scenario: Stale source
- **WHEN** the source changes, disappears, or loses eligibility before replacement
- **THEN** no edit is attempted and an explicit Copy correction action is offered

#### Scenario: Unsupported editing
- **WHEN** observation works but targeted editing is unsupported
- **THEN** practice remains available and only explicit copy/manual correction is offered
