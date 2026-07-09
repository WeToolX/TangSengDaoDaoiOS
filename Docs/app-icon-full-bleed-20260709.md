# App Icon Full Bleed - 2026-07-09

## Requirement - CONFIRMED

Replace the current rounded-corner app icon assets with square, full-bleed icon assets. The icon background must fill the complete canvas with no outer white corners or transparent padding.

## Development Plan - CONFIRMED

- Reuse the current icon artwork as the source.
- Generate a 1024x1024 full-bleed master by scaling the artwork enough to remove the built-in white rounded-corner border.
- Regenerate every image referenced by `TangSengDaoDao/Assets.xcassets/AppIcon.appiconset/Contents.json`.

## Acceptance Criteria - CONFIRMED

- All AppIcon PNG files have the exact pixel dimensions required by `Contents.json`.
- AppIcon PNG files have no alpha channel.
- AppIcon corner pixels are no longer white.
- `git diff --check` passes.

## Progress

- Requirement: CONFIRMED
- Development: DONE
- Validation: DONE
- Closure: DONE

## Validation Evidence

- Generated a new 1024x1024 full-bleed master from the existing artwork by cropping `(85, 85, 853, 853)` and scaling back to 1024x1024.
- Regenerated every PNG listed in `TangSengDaoDao/Assets.xcassets/AppIcon.appiconset/Contents.json`.
- AppIcon validation passed: every referenced PNG has the exact expected pixel size, no alpha channel, and no white corner pixels.
- `git diff --check`: passed.
- `xcodebuild -workspace TangSengDaoDaoiOS.xcworkspace -scheme WuKongChatiOS -configuration Release -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO`: passed.
