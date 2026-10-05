## ADDED Requirements

### Requirement: Completed local spelling checks
The system SHALL check completed eligible English tokens locally and SHALL suspend processing of unfinished input composition.

#### Scenario: Boundary
- **WHEN** a user finishes a misspelled natural-language token with whitespace or punctuation
- **THEN** the spelling adapter returns available correction candidates

#### Scenario: Incomplete token
- **WHEN** a token or input composition is still in progress
- **THEN** no challenge is triggered

### Requirement: Developer vocabulary filtering
The system SHALL exclude detected URLs, emails, paths, numeric tokens, underscore identifiers, camelCase identifiers, detected fenced code, and approved vocabulary.

#### Scenario: Code-like token
- **WHEN** the completed token is user_id or getUserName
- **THEN** no spelling challenge opens

#### Scenario: Approved word
- **WHEN** the user approves a domain term
- **THEN** future occurrences are excluded until the approval is removed

### Requirement: Confirmed target and duplicate suppression
The system SHALL require a user-confirmed target before practice, allow one active challenge, and suppress dismissed duplicates for 60 seconds or until the token changes, whichever occurs first.

#### Scenario: Uncertain target
- **WHEN** the checker has multiple or no suggestions
- **THEN** the user can select or enter a target, approve the word, or dismiss without automatic correction

#### Scenario: Duplicate notification
- **WHEN** the same unchanged candidate appears during its suppression interval
- **THEN** no additional challenge opens
