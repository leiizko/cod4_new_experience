# CoD4:NE Slide, Shop, Anti-Cheat, and Unified HUD

Date: 2026-11-06
Status: Draft for review
Repo: CoD4 New Experience (server-side GSC/GSX)

## 1. Problem

CoD4:NE is a widely used CoD4x server-side mod. It is dated:

- There is no player slide, so movement is stock CoD4 plus `fast_paced`.
- The credit shop is killstreaks only, with prices that push players toward late-game streaks.
- HUD elements (shop, money, killcam, spawn protection, hardpoint overlays) are each built ad-hoc with `newClientHudElem`, so cheaters can hide behind mismatched client overlays.
- Anti-cheat is only `reloadFix` (clip dump on reload). There is no per-player suspicion system.

This spec adds slide with a 10s cooldown, rebalances the shop and adds four gear items, introduces a player-level anti-cheat with a suspicion score, and restyles player-facing HUDs onto one visual template.

## 2. Goals

- Add sprint+crouch slide with a 10 second cooldown and a visible cooldown HUD.
- Rebalance the 10 existing hardpoint prices and add Extra Ammo, Extra Health, Smoke Cover, Extra Slide.
- Rebuild shop/money/slide/spawn/killcam/cheat-warning HUDs with one template.
- Track per-player suspicion (speed, fire-rate/reload, damage spikes, slide spam). Warn on HUD, then kick at threshold.
- Keep existing hardpoint buy/trigger logic. Do not rewrite killstreak scripts.

## 3. Non-goals

- Catching wallhacks or aimbots. GSC cannot see client rendering or mouse input.
- Rewriting heli/AC130/predator overlay HUDs in this pass.
- Shop tabs (Hardpoints vs Gear). One list, sorted by price.
- Client-side IWD/menu files. This remains server-side scripts only.
- MySQL persistence of cheat scores across maps. Score lives for the current map/session.

## 4. Architecture

New scripts live under `ghost/`, not `code/`. Existing `code/` and `maps/mp/gametypes/` files are patched only where needed.

```
ghost/hud.gsx         Shared HUD template (create/destroy/style helpers)
ghost/slide.gsx       Slide movement, cooldown, Extra Slide hook
ghost/anticheat.gsx   Per-player monitors, suspicion score, warn/kick
ghost/gear.gsx        Extra Ammo / Extra Health / Smoke Cover / Extra Slide buy callbacks
```

Wiring:

- `code/init.gsx` `startGameType()` threads `ghost\hud::init`, `ghost\slide::init`, `ghost\anticheat::init`, `ghost\gear::init`.
- `code/dvars.gsx` and `config.cfg` gain the new dvars listed in section 9.
- `code/hardpoints.gsx` `makeShopArray()` adds the four gear items via existing `addHardpoint()`. Shop HUD functions (`shop()`, `updateHUD()`, `moneyHud()`) switch to `ghost\hud` helpers.
- Killcam HUD in `maps/mp/gametypes/_killcam.gsx` and spawn-protection HUD in `code/spawnprotection.gsx` switch to the same helpers.
- `code/events.gsx` already supports connect/spawn/death/damage hooks. Slide and anti-cheat register through those.

Each new module has one job, talks through existing events, and can be disabled by dvar.

## 5. Shared HUD template (`ghost/hud.gsx`)

Visual language, used by every restyled HUD:

- Dark panel: shader `white`, color `(0.05, 0.05, 0.07)`, alpha `0.72`.
- Accent bar: 2px strip on the left or top edge, color `(1.0, 0.55, 0.12)`.
- Font: `objective` for titles, `default` for body. Title scale `1.5`, body `1.25`.
- Text: primary `(1, 1, 1)`, muted `(0.7, 0.7, 0.7)`, affordable `(0.45, 0.85, 0.45)`, unaffordable `(0.85, 0.25, 0.25)`.
- Padding: 8px inside panels. Selection highlight: same white shader, alpha `0.28`, accent-tinted.

Helpers (names may vary slightly in code, behavior must not):

- `createPanel(player, width, height, x, y, horz, vert)` — background + accent.
- `createLabel(player, text, font, scale, x, y, horz, vert)` — text elem with template colors.
- `createBar(player, width, height, x, y, horz, vert)` — fillable cooldown/progress bar.
- `destroyHudGroup(array)` — destroy all defined elems in an array.

HUDs that adopt the template in this pass:

- Shop list and selection (`code/hardpoints.gsx` `shop()` / `updateHUD()`).
- Money counter (`moneyHud()`).
- Slide cooldown bar (`ghost/slide.gsx`).
- Spawn protection (`code/spawnprotection.gsx`).
- Killcam chrome (`maps/mp/gametypes/_killcam.gsx` plus `code/killcam.gsx` extras).
- Anti-cheat warning banner (`ghost/anticheat.gsx`).

Hardpoint vehicle overlays (heli, AC130, predator, AGM) stay as they are.

## 6. Player sliding (`ghost/slide.gsx`)

CoD4 has no native slide. This is a server-side approximation.

Trigger: player is alive, on ground, sprinting, then presses crouch (`getStance()` moving toward `crouch`/`prone` while `sprintButtonPressed()` was true on the previous frame).

On trigger:

1. If cooldown remaining > 0, ignore and flash the cooldown bar.
2. If player is in shop, in a hardpoint vehicle, or under spawn protection, ignore.
3. Record `self.slideLastTime = getTime()`.
4. Force prone (`setStance("prone")`), apply a forward boost along `anglesToForward(self getPlayerAngles())` using repeated `setOrigin` steps over ~0.7s (CoD4 GSC has no `setPlayerVelocity`). Distance roughly 180–220 units.
5. Lock stance during the slide. Cancel early on death or if the player is frozen by another system.
6. After ~0.7s, restore crouch then stand if the player is still alive and not holding crouch.

Cooldown:

- Default 10 seconds from slide start (`slide_cooldown` dvar).
- Extra Slide shop item sets `self.slideCooldownOverride = 3` until death, then back to 10.
- HUD: bottom-right bar, shared template, visible while cooling down, hidden when ready.

Dvars: `slide_enable` (default 1), `slide_cooldown` (10), `slide_duration` (0.7).

## 7. Shop rebalance and new items

### 7.1 Price rebalance

Existing 10 hardpoints stay; only credit costs change. Buy/trigger callbacks stay in `code/hardpoints.gsx`.

| Item | Old | New |
|------|-----|-----|
| Radar | 20 | 15 |
| Airstrike | 70 | 50 |
| Artillery | 70 | 55 |
| Hellfire (AGM) | 100 | 80 |
| Fighter Support (ASF) | 100 | 90 |
| Helicopter | 180 | 140 |
| Predator | 280 | 220 |
| AC130 | 380 | 300 |
| Manned Helicopter | 500 | 400 |
| Thermonuclear Bomb | 600 | 550 |

Update both `config.cfg` and `code/dvars.gsx` defaults.

### 7.2 New gear items

Added through `addHardpoint()` so they sort into the same price list. Callbacks live in `ghost/gear.gsx`. Effects last until death unless noted.

| Dvar key | Name | Price | Effect |
|----------|------|-------|--------|
| `ammo_shop` | Extra Ammo | 40 | `giveMaxAmmo` on current primary and secondary. |
| `health_shop` | Extra Health | 60 | Set max/health to 150 (stock 100) until death. |
| `smoke_shop` | Smoke Cover | 35 | Give one `smoke_grenade_mp`. If the player already has one, add +1 ammo. If the weapon cannot be given, return false. |
| `slide_shop` | Extra Slide | 50 | Set slide cooldown to 3s until death. Does not grant an extra charge. |

Buy still spends credits only if the callback returns true. Extra Health refused if already active. Extra Slide refused if already active. Extra Ammo refused if both guns are already full.

### 7.3 Shop HUD

Rebuild `shop()` / `updateHUD()` / `moneyHud()` with `ghost\hud` panels:

- Centered panel, item name left, price right.
- Green price if `self.money >= cost`, red otherwise.
- Selection row uses the template highlight, not the old 16.9px white bar.
- Hint line still shows melee/use or W/S plus attack-to-buy.
- Money HUD: bottom-right, `$` label, template font/colors, sits above the slide bar.

## 8. Player-level anti-cheat (`ghost/anticheat.gsx`)

GSC cannot detect wallhacks or aimbots. This system flags server-visible impossibilities and abuse of the new slide.

Per player, reset on connect:

- `self.acScore` integer, 0.
- `self.acFlags` array of recent flag strings.
- `self.acWarned` bool.

Monitors (each adds to `acScore`, logs a flag):

1. Speed: sample origin every 0.1s while alive and not in a hardpoint vehicle. Horizontal speed above `g_speed * sprintscale * 1.35` (and not currently sliding) is a flag. +15 score.
2. Fire-rate / reload: keep `reloadFix`. Additionally, if shots-per-second on a weapon exceed a generous stock multiplier (2x fire time), flag. +10 score.
3. Damage spikes: on `PlayerDamage` as attacker, if more than 10 hits land in a 1s window, flag. +10 score.
4. Slide spam: slide attempts while cooldown > 0 more than 3 times in 5s. +8 score. The slide module itself already ignores the attempt.

Actions:

- At `anticheat_warn` (default 30): show a top-center warning banner via the HUD template: "Movement / fire pattern flagged". Set `acWarned`.
- At `anticheat_kick` (default 60): `kick(self getEntityNumber(), "Anti-cheat: suspicion threshold")`.
- Admins (`isVIP()`) get a new `acflags` script command showing name, score, and last flags.

False-positive guards:

- Do not sample during slide, hardpoint control, killcam, or spawn protection.
- Do not flag falling or explosive knockback.
- Disable entirely with `anticheat_enable 0`.

This is a deterrent and a kick hammer for obvious script abuse, not a replacement for a client anti-cheat.

## 9. Dvars

Add to `config.cfg` and `code/dvars.gsx`:

```
slide_enable 1
slide_cooldown 10
slide_duration 0.7

ammo_shop 40
health_shop 60
smoke_shop 35
slide_shop 50

anticheat_enable 1
anticheat_warn 30
anticheat_kick 60
```

Hardpoint `*_shop` defaults change to the table in 7.1.

## 10. Data flow

Connect: hud init (none yet) -> anticheat reset score -> player money HUD.

Spawn: slide watcher thread -> anticheat sampler threads -> gear effects from previous life already cleared on death.

Slide attempt: slide.gsx checks cooldown and blockers -> either boost+HUD bar or ignore (anticheat may count ignored spam).

Shop buy: existing `buy()` -> callback in hardpoints or `ghost/gear.gsx` -> money HUD update.

Damage/kill: existing events -> anticheat damage monitor; hardpoints money on kill unchanged.

Death: clear Extra Health / Extra Slide; destroy slide bar; anticheat keeps score (session-level).

## 11. Error handling

- Missing smoke weapon: Smoke Cover callback returns false and prints "Smoke not available".
- Slide into solid: `bulletTrace` / `sightTracePassed` the next origin; stop the slide on collision instead of pushing through walls.
- HUD elem leaks: every HUD group destroyed on death, disconnect, shop close, and `game_ended`.
- Kick during hardpoint: end the hardpoint the same way disconnect already does.

## 12. Testing

Cannot run a live CoD4x server in this workspace. Verification is script-level:

- `addHardpoint` list contains 14 entries after sort, prices match the table, gear callbacks are defined.
- Slide ignores input when `getTime() - slideLastTime < cooldown * 1000`.
- Extra Slide buy sets override to 3, death clears it.
- Anti-cheat does not increment during spawn protection or slide.
- Warn fires once at 30, kick at 60.
- Every new HUD path calls `destroyHudGroup` on death/disconnect.

Manual on a real CoD4x server after deploy: slide feel, shop buy of all four gear items, fake speed by temporarily lowering the speed threshold, confirm warn then kick.

## 13. File change list

New:

- `ghost/hud.gsx`
- `ghost/slide.gsx`
- `ghost/anticheat.gsx`
- `ghost/gear.gsx`

Edit:

- `code/init.gsx` — start the four modules
- `code/dvars.gsx` — new dvars + new shop defaults
- `config.cfg` — same
- `code/hardpoints.gsx` — register gear, restyle shop/money HUD
- `code/spawnprotection.gsx` — restyle HUD
- `maps/mp/gametypes/_killcam.gsx` and `code/killcam.gsx` — restyle HUD
- `code/scriptcommands.gsx` — `acflags` command for VIPs
- `README.md` — short feature notes

## 14. Risks

- Slide via `setOrigin` can look teleporty or fail on stairs. Tune duration and trace.
- Speed monitor false positives on `fast_paced` servers. Threshold is relative to `g_speed` and sprint scale.
- Shop string length: 14 items may overflow the old single-string HUD; the new panel list avoids that.
- Kick threshold too low on chaotic TDM. Defaults are conservative; admins can raise `anticheat_kick` or disable.
