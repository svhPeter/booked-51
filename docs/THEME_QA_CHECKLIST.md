# Theme QA Checklist

## Light Mode (default)

### Home Screen
- [ ] Header greeting text is dark (#0F172A) on white/light gray background
- [ ] Search bar has light background with readable hint text
- [ ] Service cards have white backgrounds with dark text
- [ ] Specialty grid items are visible with proper contrast
- [ ] Trust banner has light green background with dark green text
- [ ] Next appointment card (blue gradient) has white text

### Admin Dashboard
- [ ] Summary cards have light tinted backgrounds with colored icon/value
- [ ] Management cards are white with dark text (#0F172A)
- [ ] Count text is readable (#475569)
- [ ] Chevron icons are visible (#94A3B8)

### Admin Doctors
- [ ] Doctor cards are white with dark text
- [ ] Specialty/fee text is readable gray (#475569)
- [ ] Status badges have proper colors (green=approved, amber=pending, red=inactive)

### Profile Screen
- [ ] Theme selector shows correct selection indicator
- [ ] Personal information form fields have light backgrounds
- [ ] Support/legal tiles have readable text

### All Screens
- [ ] Cards have white backgrounds (#FFFFFF) with dark text
- [ ] App bar has white background with dark text and icons
- [ ] Bottom nav shows selected tab in blue, unselected in gray
- [ ] Buttons are blue (#2563EB) with white text
- [ ] Text fields have white fill with dark labels
- [ ] Dialog/bottom sheet backgrounds are white
- [ ] Snackbars are dark with white text
- [ ] No low-contrast or washed-out text
- [ ] No white-on-white or gray-on-white issues

## Dark Mode

### Home Screen
- [ ] Background is dark (#0F172A)
- [ ] Card backgrounds are dark surface (#1E293B)
- [ ] Header text is light (#F1F5F9)
- [ ] Subtitle/tertiary text is readable (#CBD5E1 / #64748B)
- [ ] Search bar has dark surface background with light hint text
- [ ] Service cards have dark surface with light text
- [ ] Specialty icons are visible against dark background
- [ ] Trust banner has dark green background with green text
- [ ] Next appointment card (blue gradient) has white text

### Admin Dashboard
- [ ] Summary cards have dark tinted backgrounds with colored icon/value
- [ ] Management cards are dark surface (#1E293B) not white
- [ ] Card text is light (#F1F5F9)
- [ ] Count/chevron text is readable (#CBD5E1)
- [ ] Section headers are visible

### Admin Doctors
- [ ] Doctor cards are dark (#1E293B) with light text (#F1F5F9)
- [ ] Specialty/fee text is readable (#CBD5E1)
- [ ] Status badges are visible (green=approved, amber=pending, red=inactive)
- [ ] Detail bottom sheet has dark background with readable text

### Profile Screen
- [ ] Theme selector shows correct selection with highlighted background
- [ ] Form fields have dark variant fill (#334155)
- [ ] All text is readable (light on dark)
- [ ] Warning banner has dark amber background with amber text

### All Screens
- [ ] No white cards anywhere (unless intentionally white for contrast)
- [ ] No washed-out or invisible text
- [ ] App bar shows dark surface (#1E293B) with light text/icons
- [ ] Bottom nav has dark background (#0F172A) with light icons
- [ ] Buttons use primary light (#60A5FA) with dark text
- [ ] Text fields have dark fill (#334155) with light labels/hints
- [ ] Borders are dark (#334155)
- [ ] Dialog/bottom sheet backgrounds are dark (#1E293B)
- [ ] Snackbars are dark variant with light text
- [ ] No dark-on-dark unreadable text
- [ ] Selected tab/indicator is visible

## System Mode
- [ ] Switching device setting to Dark mode causes app to switch to dark
- [ ] Switching device setting to Light mode causes app to switch to light
- [ ] App responds in real-time (no restart needed)

## Theme Selector (Profile Screen)
- [ ] "System default" sets ThemeMode.system
- [ ] "Light" forces light mode regardless of device setting
- [ ] "Dark" forces dark mode regardless of device setting
- [ ] Selection persists after app restart
- [ ] Selection indicator (check/radio) updates immediately

## Testing Steps

### iOS
1. Open Settings → Display & Brightness → toggle Light/Dark
2. Launch app → verify theme follows device setting (System mode)
3. Go to Profile → Appearance → select Dark → app switches immediately
4. Select Light → app switches back
5. Select System → verify it follows device again
6. Kill app → reopen → verify theme selection persisted
7. Change device theme → verify System mode follows

### Android
1. Open Settings → Display → Dark theme → toggle
2. Launch app → verify theme follows device setting (System mode)
3. Go to Profile → Appearance → test all 3 options
4. Verify persistence across app restart

## Known Limitations
- Admin screens may still have some hardcoded light colors in charts/graphs
- Some third-party widgets (Agora video call) may not respect dark mode
- Web/folder icons may use fixed colors from asset files
