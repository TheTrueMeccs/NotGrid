# NotGrid
NotGrid is a party and raid frame addon for Vanilla World of Warcraft (1.12.1). While heavily based off of the original addon Grid, it both lacks some Grid features as well as adds new ones. It supports Clique keybinds & macros, Lazyspell, healcomm, configurable debuff spell icons, low mana & aggro warning, proximity checking, pets, and a simple config menu for general resizing/coloring options.

![Screenshot](media/screenshot.jpg)

## Usage
Use */notgrid* or */ng* to show the config menu.  
Use */notgrid grid* to generate a style similar to the original grid.  
Use */notgrid reset* to restore the default settings.  
Open **Profiles** near the top of `/ng`, or use `/ng profiles`, to share or copy settings across characters on the same WoW account. On first load, each character's existing settings become its own profile named `Character - Realm`. Log into each source character once after updating so its profile becomes available to your other characters.

Select a profile and use **Copy From** to replace your current profile's settings with an independent copy. Use **Create From Current** to save your current setup under a new name. **Use Profile** lets multiple characters share the same profile, including future edits. **Reset Current Profile** restores defaults, and **Delete Profile** removes profiles that no character uses. Copy, reset, and delete ask for confirmation. Creating, using, copying, or resetting a profile reloads the UI. Frame positions are included; Config Mode is turned off when applying a profile.

In `/ng`, use **Show Debuff Icons**, the five debuff-type filters, **Debuff Icon Size**, and **Debuff Icon Count** to configure debuff spell icons. **Debuff Anchor** selects any health bar corner: top-left, top-right, bottom-left, or bottom-right. **Debuff Growth Direction** independently selects up, down, left, or right. **Debuff Horizontal Margin** and **Debuff Vertical Margin** are measured from the selected corner: positive values move inward, negative values move outward. Existing margin settings are preserved. **Debuff Icon Spacing** sets the gap between icons. Defaults remain top-left, growing down, with 1-pixel margins and spacing. Large inward margins are limited by the frame size. Inward rows/columns fit inside the health bar; outward growth can extend beyond the frame.

**Debuff Type Border** colors the unit border to match the first displayed debuff: Magic blue, Curse purple, Disease brown, Poison green, or red for other debuffs (using the client's type colors). It takes priority over the target, aggro, and low-mana border while active; the usual border returns when the debuff clears.

The old corner and out-of-combat buff indicators have been removed. Their saved settings are cleaned up automatically on load. Disabling **Show Debuff Icons** hides the debuff icons and their type-colored unit border.

Enable **Config Mode** in `/ng` to preview sample debuffs, stack counts, and matching borders on every preview frame. Type filters, icon size/count, anchor, growth direction, margins, spacing, and the border toggle apply to the samples immediately; leaving Config Mode restores real debuffs.

Use */ngcast spellname(Rank X)* in macros for mouseover casting.

## Development checks
The optional [UnitXP range extension](https://github.com/MarcelineVQ/UnitXP_SP3) is detected safely. Clients without its line-of-sight/distance commands use the normal interaction, spell, and map range checks instead.

Run `lua5.1 tests/proximity.lua` to check range detection with the base client API, the optional UnitXP extension, and unavailable/invalid extension results.

Run `lua5.1 tests/debuffs.lua` from the addon directory for isolated checks of aura filtering, icon layout, border priority, and saved-setting/menu compatibility. These checks use mocked WoW APIs; verify rendering and combat behavior in the game as well.

Run `lua5.1 tests/startup.lua` to check frame visibility on login, reload, and world entry without requiring a roster-change event, including solo, party, raid, and saved visibility settings.

Run `lua5.1 tests/menu.lua` to check the complete menu setup during startup, including clients without the `APPLY` global, English/Russian labels, and debuff selector wiring.

Run `lua5.1 tests/profiles.lua` to check character migration, sharing, independent copies, persistence, reset/delete protection, position saving, and profile controls.

## Optional Dependencies
Clique: Enables click-casting on your unit frames.  
LazySpell: Enables Clique and /ngcast auto spell rank scaling depending on unit health deficit.

## Additional Note
If you're having issues with the frame borders/edges being un-uniformly sized or appearing clipped by the healthbar make sure to have a proper [UI scale](http://wow.gamepedia.com/UI_Scale) set.  
TLDR: If you play with a 1920x1080 resolution, the correct UI scale would be 768/1080 = 0.7111..., and you would set that by typing */console UIScale 0.7111111111* in the chat.
