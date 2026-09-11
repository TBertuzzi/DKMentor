# DK Mentor 2.0.8 live test checklist

1. Replace the previous DKMentor folder with the 2.0.8 test build and reload the UI.
2. Complete a combat lasting at least 5 seconds with only one generated insight.
3. Verify the DK Mentor Score popup is narrow/short and contains no large empty area.
4. Generate two or three insights and verify the card grows vertically only enough for the wrapped lines.
5. Verify long PT-BR insight text wraps inside the card without clipping or extending off-screen.
6. If four report insights are generated, verify only three are shown and the last visible line receives a compact `(+1 a mais)` suffix in PT-BR.
7. Verify the popup remains click-through and disappears automatically after about 12 seconds.
8. Open `/dkm insights` and verify the full last-combat report remains available there.
9. Recheck resource arc click-through/edit handle, active-only aura HUDs, DK Status widget and Mind Freeze alert for regressions.
