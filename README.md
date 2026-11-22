# NotGrid
NotGrid is a party and raid frame addon for Vanilla World of Warcraft (1.12.1). While heavily based off of the original addon Grid, it both lacks some Grid features as well as adds new ones. It supports Clique keybinds & macros, Lazyspell, healcomm, eight buff/debuff icons around the unit frame, low mana & aggro warning, proximity checking, pets, and a simple config menu for general resizing/coloring options.

![Screenshot](media/screenshot.jpg)

## Usage
Use */notgrid* or */ng* to show the config menu.  
Use */notgrid grid* to generate a style similar to the original grid.  
Use */notgrid reset* to restore the default settings.  
Use / for separating multiple Buffs/Debuffs to track on one icon.  
Debuff spell icons start at the top-left corner of each unit frame and grow downward. In `/ng`, use **Show Debuff Icons**, the five debuff-type filters, **Debuff Icon Size**, and **Debuff Icon Count** to configure them. **Debuff Left Margin** and **Debuff Top Margin** move the column relative to the health bar: positive values move right/down, negative values move left/up. **Debuff Icon Spacing** sets the gap between icons. All three default to 1 pixel, preserving the original layout. Large inward margins are limited by the frame size, and the column fits above the health bar's bottom edge; increase frame height or reduce icon size/spacing to display more icons.

**Debuff Type Border** colors the unit border to match the topmost displayed debuff: Magic blue, Curse purple, Disease brown, Poison green, or red for other debuffs (using the client's type colors). It takes priority over the target, aggro, and low-mana border while active; the usual border returns when the debuff clears.

With debuff icons enabled, the existing corner indicators track buffs. Disabling **Show Debuff Icons** restores their original buff/debuff behavior and keeps your saved indicator settings.

Enable **Config Mode** in `/ng` to preview sample debuffs, stack counts, and matching borders on every preview frame. Type filters, icon size/count, margins, spacing, and the border toggle apply to the samples immediately; leaving Config Mode restores real debuffs.

Use */ngcast spellname(Rank X)* in macros for mouseover casting.

## Development checks
Run `lua5.1 tests/debuffs.lua` from the addon directory for isolated checks of aura filtering, icon layout, border priority, and saved-setting/menu compatibility. These checks use mocked WoW APIs; verify rendering and combat behavior in the game as well.

## Optional Dependencies
Clique: Enables click-casting on your unit frames.  
LazySpell: Enables Clique and /ngcast auto spell rank scaling depending on unit health deficit.

## Additional Note
If you're having issues with the frame borders/edges being un-uniformly sized or appearing clipped by the healthbar make sure to have a proper [UI scale](http://wow.gamepedia.com/UI_Scale) set.  
TLDR: If you play with a 1920x1080 resolution, the correct UI scale would be 768/1080 = 0.7111..., and you would set that by typing */console UIScale 0.7111111111* in the chat.
