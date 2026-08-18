# Tutorial Setup — Zero Edits to Existing Code

This version does **not** require touching `game.gd`, `shop.gd`, `tractor.gd`,
`character_body_2d.gd`, or any vegetable script. It lives entirely in its own
scene + script, and hooks itself in automatically.

## 1. Build the scene

Create a new scene, root node type **Control**, name it `Tutorial`.
Attach `tutorial.gd` as its script.

```
Tutorial (Control root — script: tutorial.gd)
├── ColorRect            (full rect, dark semi-transparent)
├── TitleLabel             (Label, big font, centered)
├── BodyLabel               (Label, autowrap word, centered)
├── StepIndicatorLabel    (Label, e.g. "2 / 6") — optional
├── NextButton              (Button)
└── SkipButton               (Button, text "Skip Tutorial") — optional
```

- Select the root `Tutorial` node → Layout → Anchors Preset → **Full Rect**.
- Save as `tutorial.tscn` anywhere in your project (e.g. `res://tutorial.tscn`).

You don't need to touch `game.tscn`, `shop.tscn`, or anything else — this is
a completely separate scene, like its own extra tab.

## 2. Register it as an Autoload

This is the part that means the game doesn't need to know it exists.

Go to **Project → Project Settings → Autoload**.
- Path: `res://tutorial.tscn`
- Node Name: `Tutorial` (or anything you like)
- Click **Add**.

Autoloaded scenes get added directly under the tree root automatically, at
startup, before your `Game` scene even runs — no code anywhere else needs to
reference it, spawn it, or know it's there.

## 3. That's it — how it works

- On startup, `tutorial.gd` waits a frame for `Game` to exist, then checks
  a save flag (`user://tutorial_seen.save`). If the player hasn't seen it,
  it shows itself and sets `get_tree().paused = true`.
- Because every one of your existing scripts uses the default **Inherit**
  process mode, pausing the tree automatically freezes the player, tractor,
  vegetables, and the day timer in `game.gd` — no `set_physics_process(false)`
  calls needed anywhere.
- The `Tutorial` node's own process mode is set to **Always** in code
  (`process_mode = Node.PROCESS_MODE_ALWAYS`), so its buttons keep working
  while everything else is frozen.
- Clicking through to the last step (or hitting Skip) sets
  `get_tree().paused = false` and saves the "seen" flag, and the game resumes
  exactly where it was.

## 4. Testing

To re-trigger the tutorial while iterating, delete the save file:
- Windows: `%APPDATA%\Godot\app_userdata\<your project name>\tutorial_seen.save`
- Or just delete the `if has_seen_tutorial(): return` check temporarily.

## 5. Double-check

The key names in the popup text (E for the tractor, Space for dash) are
guesses — confirm against **Project Settings → Input Map** for your
`enter_vehicle` and `dash` actions and edit the strings in
`get_tutorial_steps()` if they differ.
