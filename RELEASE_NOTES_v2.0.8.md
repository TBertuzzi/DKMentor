# DK Mentor 2.0.8 - Dynamic compact Combat Insights popup

Version 2.0.8 makes the post-combat score card adapt to what it actually has to say.

- The popup no longer reserves a fixed 500x116 rectangle.
- Short reports shrink to a compact card.
- Longer translated insights wrap and grow the card only as needed.
- Width stays between 300 and 480 UI pixels and is additionally capped relative to the current UI width.
- Height is derived from rendered text height.
- Up to three insights are shown; extra observations collapse into a small `(+N more)` suffix.
- The title uses a smaller heading font for less screen obstruction.
- The complete report remains available in Adaptive DK Coach / `/dkm insights`.
- Popup remains mouse-transparent and still auto-hides after 12 seconds.
