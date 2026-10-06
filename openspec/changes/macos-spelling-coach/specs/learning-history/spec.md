## ADDED Requirements

### Requirement: Minimal local records
The system SHALL persist confirmed target words, locale, counts, review state, and timestamps locally without raw input text or source document identifiers.

#### Scenario: Completed practice
- **WHEN** a confirmed-word session finishes
- **THEN** its learning record is updated without persisting the observed source text

#### Scenario: False positive
- **WHEN** a candidate is dismissed as incorrect detection
- **THEN** no learning record is created

### Requirement: Deterministic spaced review
The system SHALL schedule reviews after 1, 3, 7, 14, and 30 days, repeat the final interval, reset to one day following an incorrect submitted round or fresh observed mistake, and never advance abandoned sessions.

#### Scenario: First success
- **WHEN** a new word is practiced successfully
- **THEN** its first review is due one day after completion

#### Scenario: Due review success
- **WHEN** a due review at the one-day stage finishes without errors
- **THEN** the next review is due three days after completion

#### Scenario: Practice error
- **WHEN** a completed session contains an incorrect submitted round
- **THEN** the next review is due one day after completion

#### Scenario: Abandoned review
- **WHEN** a review is skipped
- **THEN** its due date and stage do not advance

### Requirement: Data control and recovery
The app SHALL support individual learning-record deletion and deletion of all learning records, use atomic versioned writes, and surface unreadable storage without silently overwriting it.

#### Scenario: Delete learning data
- **WHEN** the user confirms deletion of all learning records
- **THEN** history and review queues are cleared and remain empty after restart

#### Scenario: Unreadable store
- **WHEN** the persisted store cannot be decoded
- **THEN** the file is preserved and the user sees recovery/reset options
