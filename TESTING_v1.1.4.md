# Testing DK Mentor 1.1.4

1. Install over 1.1.3 without deleting SavedVariables.
2. Run `/reload` and confirm there is no Lua error during `CreateUI`.
3. Select Classic DK Resources and confirm it still uses its saved/default position.
4. Select DK Arcs and confirm it remains centered and has no move handle.
5. Confirm left Health arc orientation is correct.
6. Confirm Health arc turns red at 30% HP or less and returns green above 30%.
7. Disable numeric resource text and confirm the red low-health color still works.
