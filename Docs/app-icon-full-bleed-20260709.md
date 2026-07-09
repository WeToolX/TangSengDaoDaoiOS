# App Icon Full Bleed - 2026-07-09

## Requirement - CONFIRMED

Replace the current rounded-corner app icon assets with square, full-bleed icon assets. The icon background must fill the complete canvas with no outer white corners or transparent padding.

## Development Plan - CONFIRMED

- Reuse the current icon artwork as the source.
- Generate a 1024x1024 full-bleed master with the orange background filling the canvas and the paper-plane artwork centered inside the visual safe area.
- Do not center-crop the full artwork. Keep the subject within about 760-820px, leaving about 100-130px visual safe margin.
- Regenerate every image referenced by `TangSengDaoDao/Assets.xcassets/AppIcon.appiconset/Contents.json`.

## Acceptance Criteria - CONFIRMED

- All AppIcon PNG files have the exact pixel dimensions required by `Contents.json`.
- AppIcon PNG files have no alpha channel.
- AppIcon corner pixels are no longer white.
- AppIcon master uses RGB output, no rounded corners, no transparent padding, and no outer white background.
- The paper-plane subject is centered and not cropped by the 1024x1024 canvas.
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
- Runtime review on 2026-07-09 showed the 1.20x center-cropped icon could visually cut the paper-plane subject.
- Follow-up plan regenerates the icon with a full orange background and centered subject safe margin instead of center-cropping.
- Follow-up AppIcon generation produced a 1024x1024 RGB master with orange full-bleed corners and the extracted subject centered at 691x800px.
- Follow-up AppIcon validation passed for 15 referenced PNG files: exact pixel sizes, no alpha channel, no white corners.
- Follow-up Release generic iOS build produced app icon files in `TangSengDaoDao.app`.
