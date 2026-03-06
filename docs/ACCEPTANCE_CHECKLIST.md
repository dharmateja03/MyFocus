# Acceptance Checklist

## Functional scenarios
- Start a 25-minute session and verify timer decrements once per second.
- Open a blocked app during an active session and verify it is hidden immediately.
- Pause and resume a session from both the window UI and menu bar UI.
- Stop a running session and verify it appears in local history.
- Restart the app during an active session and verify it rehydrates state.

## Permission scenarios
- Deny Accessibility permission and verify blocking is not enforced.
- Grant Accessibility permission and verify enforcement resumes.
- Deny Notification permission and verify app remains functional.

## Performance scenarios
- Run idle for 30 minutes and verify average CPU remains under 1%.
- Verify resident memory remains under 100MB during idle monitoring.
- During active session enforcement, verify no sustained CPU spikes.
