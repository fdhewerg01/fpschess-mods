# UE4SS debug console fix

The game-local UE4SS configuration is not part of `FPSChessAugmentChess.zip` and is not applied by the mod auto-updater. Apply this per-install fix to:

`FPSChess/Binaries/Win64/UE4SS-settings.ini`

Under `[Debug]`, set:

```ini
ConsoleEnabled = 0
GuiConsoleEnabled = 0
GuiConsoleVisible = 0
```

Under `[ExperimentalFeatures]`, set:

```ini
GUIUFunctionCaller = 0
```

Do not replace the whole settings file with a copy from another computer. In particular, `ModsFolderPath` can be an installation-specific absolute path. Restart FPS Chess after changing the values.
