---
version: beta
name: Burnline
description: Native macOS usage instrument built with Apple Liquid Glass.
colors:
  primary: "#F5F7FF"
  secondary: "#AEB4C5"
  accent: "#5E5CE6"
  cyan: "#38B8F2"
  success: "#30D158"
  warning: "#FF9F0A"
  surface-dark: "#10131B"

typography:
  display:
    fontFamily: SF Pro Rounded
    fontSize: 2.375rem
    fontWeight: 600
    lineHeight: 1
    letterSpacing: "-0.03em"
  body:
    fontFamily: SF Pro Text
    fontSize: 0.8125rem
    fontWeight: 500
    lineHeight: 1.3
  meta:
    fontFamily: SF Pro Text
    fontSize: 0.65625rem
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.07em"
rounded:
  sm: 10px
  md: 14px
  lg: 20px
  xl: 24px
spacing:
  xs: 4px
  sm: 8px
  md: 11px
  lg: 14px
  xl: 17px
components:
  panel:
    backgroundColor: "system ultraThinMaterial"
    textColor: "system primary"
    rounded: "{rounded.xl}"
    padding: "{spacing.lg}"
  glass-card:
    backgroundColor: "system Liquid Glass regular"
    rounded: "{rounded.xl}"
    padding: "{spacing.xl}"
  glass-control:
    backgroundColor: "system Liquid Glass interactive"
    rounded: "{rounded.md}"
  agent-symbol:
    backgroundColor: "system Liquid Glass tinted"
    rounded: "{rounded.sm}"
    size: 31px
  status-dot:
    backgroundColor: "{colors.success}"
    size: 6px
  brand-mark:
    backgroundColor: "{colors.accent}"
    textColor: "{colors.primary}"
    rounded: "{rounded.lg}"
  brand-terminal:
    backgroundColor: "{colors.cyan}"
    rounded: "{rounded.sm}"
    size: 6px
  warning-state:
    textColor: "{colors.warning}"
  app-icon:
    backgroundColor: "{colors.surface-dark}"
    textColor: "{colors.primary}"
    rounded: "{rounded.xl}"
---

## Intent

Burnline is a compact macOS instrument, not a tiny web dashboard. The surface should feel suspended under the menu bar: clear hierarchy, native typography, restrained color, and system material doing the visual work.

## Liquid Glass

On macOS 26 and newer, custom surfaces use SwiftUI `glassEffect` with continuous shapes. The total, agent group, icon lenses, and small controls use different material scale rather than different decorative styles. The menu remains readable on every desktop because text uses system semantic colors and the glass carries native vibrancy.

On macOS 14 and 15, the same hierarchy falls back to `ultraThinMaterial` with a quiet hairline. Reduce Transparency replaces all translucent material with the system window background.

Glass is structural, not decoration:

- The spend total is the primary glass volume.
- Agent rows share one glass group instead of becoming five floating cards.
- Small icon lenses and buttons are interactive glass elements.
- Two low-opacity color fields sit behind the material so refraction is visible without becoming a gradient-heavy background.

## Color

Indigo is the Burnline signal. Cyan is a secondary optical highlight. Agent tints only identify sources and stay inside their icon lenses. Green means a successful local read; orange means data could not be read. No neon glows, rainbow borders, or decorative blobs.

The system owns light and dark appearance. Hard-coded page backgrounds are forbidden.

## Typography

Use San Francisco throughout. The spend figure uses SF Pro Rounded at a restrained semibold weight with tabular digits. Metadata uses SF Pro Text instead of monospace so the panel remains native and calm. Tracking is tightened only for the large number and opened slightly for short uppercase labels.

## Layout

The panel is 388 points wide with 14-point outer spacing. Content order is fixed:

1. identity and refresh
2. time range
3. total spend and two supporting metrics
4. provider breakdown
5. local-state footer

The provider list is one continuous surface. Separators begin after the symbol column so related content stays grouped.

## Motion

The menu bar uses the compact full-color Burnline mark rather than an abstract waveform, so the popover’s anchor is immediately identifiable. Pressing the mark triggers one 220 ms scale response. There is no idle animation. Reduce Motion disables the response.

Refresh feedback is a short 220 ms smooth rotation. There are no staged card entrances, bouncing rows, parallax, or looping background motion. Frequently used controls respond immediately.

## Accessibility

- System semantic colors preserve contrast in light and dark appearances.
- Reduce Transparency swaps glass for an opaque system surface.
- Reduce Motion minimizes the waveform update rate.
- Icon-only controls have explicit accessibility labels.
- Totals combine into one useful VoiceOver summary.
- Provider state is never communicated by color alone.

## Brand Mark

The mark is a glass lens carrying a single spend waveform and terminal dot. It expresses many local agent streams collapsing into one readable signal. The app icon and menu bar item use the same indigo glass tile so the product is recognizable at a glance.

## Do / Do Not

- Do let macOS materials, vibrancy, and system controls lead.
- Do keep the total readable in one glance.
- Do label estimates and missing usage honestly.
- Do use continuous corner geometry.
- Do not simulate glass with white opacity alone on macOS 26.
- Do not stack translucent cards inside translucent cards.
- Do not use marketing gradients, sparkles, robot imagery, or oversized copy.
- Do not show unknown spend as a trustworthy `$0.00`.
