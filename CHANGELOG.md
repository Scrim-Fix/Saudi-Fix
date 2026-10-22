# Changelog

Saudi-Fix © 2026 - Rashid Alghamdi

## v2.0

### New
- Main menu rebuilt into 7 sections: Process & Services, FPS & Gaming, Input Latency, PC Clean & Memory, Power & CPU, Debloat, System Tools
- Process & Services section with a live process counter, 18 options and a "Show What Is Running" report
- svchost grouping by installed RAM (usually 30-50 fewer processes)
- 20+ tracking and telemetry scheduled tasks disabled, re-enabled by Revert
- Widgets, Copilot and Teams Chat off; Edge background off; Delivery Optimization uploads off
- Optional groups with warnings: Search, SysMain, Printing, Bluetooth, Xbox, Diagnostics, Phone Link, Maintenance
- Longer bloatware list, with a clear list of apps that are kept
- Laptop detection: the recommended preset skips the high-performance power plan on laptops

### Safety
- Original start type of every service is saved before it changes; Revert restores it exactly
- Original device power settings and USB power values are saved and restored
- BitLocker protection is suspended for one restart before BCD timer changes
- Memory Integrity is never forced back on; Revert opens Windows Security instead
- Write cache skips USB drives; DirectX settings are merged instead of overwritten
- Warning when the tool runs under a different admin account than the signed-in user

### Docs
- ReadMe.txt rewritten with a step-by-step Arabic and English guide for every option
- README.md, LICENSE, VirtualBox testing guide, publishing guide

## v1.0
- First version, not published
