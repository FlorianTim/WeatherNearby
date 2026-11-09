# Integration Test Report

**Generated:** 2026-05-14 16:02:40 UTC

**Version:** 0.1.0

## Counter App Tests

This report contains screenshots captured during automated integration tests of the Flutter counter application.


## Tablet (1024×768) Screenshots

### Test Screenshots


#### 01 Initial State

![01 Initial State](../../apps/mobile_app/test_results/screenshots/tablet/01-initial-state.png)


#### 02 Before Tap

![02 Before Tap](../../apps/mobile_app/test_results/screenshots/tablet/02-before-tap.png)


#### 03 After First Tap

![03 After First Tap](../../apps/mobile_app/test_results/screenshots/tablet/03-after-first-tap.png)


#### 04 After Multiple Taps

![04 After Multiple Taps](../../apps/mobile_app/test_results/screenshots/tablet/04-after-multiple-taps.png)


#### 05 Final State

![05 Final State](../../apps/mobile_app/test_results/screenshots/tablet/05-final-state.png)


#### 06 Ui Elements

![06 Ui Elements](../../apps/mobile_app/test_results/screenshots/tablet/06-ui-elements.png)


#### 07 Tooltip Visible

![07 Tooltip Visible](../../apps/mobile_app/test_results/screenshots/tablet/07-tooltip-visible.png)


## Phone Portrait (390×844) Screenshots

### Test Screenshots


#### 01 Initial State

![01 Initial State](../../apps/mobile_app/test_results/screenshots/phone-portrait/01-initial-state.png)


#### 02 Before Tap

![02 Before Tap](../../apps/mobile_app/test_results/screenshots/phone-portrait/02-before-tap.png)


#### 03 After First Tap

![03 After First Tap](../../apps/mobile_app/test_results/screenshots/phone-portrait/03-after-first-tap.png)


#### 04 After Multiple Taps

![04 After Multiple Taps](../../apps/mobile_app/test_results/screenshots/phone-portrait/04-after-multiple-taps.png)


#### 05 Final State

![05 Final State](../../apps/mobile_app/test_results/screenshots/phone-portrait/05-final-state.png)


#### 06 Ui Elements

![06 Ui Elements](../../apps/mobile_app/test_results/screenshots/phone-portrait/06-ui-elements.png)


#### 07 Tooltip Visible

![07 Tooltip Visible](../../apps/mobile_app/test_results/screenshots/phone-portrait/07-tooltip-visible.png)


## Test Summary

The integration tests verify:
- [x] Initial application state
- [x] Counter increment functionality
- [x] UI element presence and layout
- [x] Button tooltip functionality
- [x] State persistence across interactions

## Running Tests

To regenerate this report:

```powershell
# Run integration tests (all profiles)
.\scripts\build.ps1 integration-web

# Generate documentation
.\scripts\automation\integration-test\generate_test_docs.ps1

# Generate versioned PDF
.\scripts\automation\integration-test\generate_test_report_pdf.ps1
```
