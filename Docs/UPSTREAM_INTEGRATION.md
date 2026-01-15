# Upstream Flag Resource Integration & Maintenance Guide

This document is intended for **maintainers of CircleFlagsKit**.
It explains how to introduce and continuously synchronize upstream flag resources using **Git submodules + automation scripts**, and how to reliably convert them into the PNG format required by CircleFlagsKit.

> Regular users **do not need** to read this document.

---

## 🎯 Design Goals

* ✅ **No manual maintenance of flag assets**
* ✅ Reproducible and auditable generation process
* ✅ Controlled upstream updates (no accidental API breakage)
* ✅ CI-verifiable resource correctness
* ✅ Package consumers fetch only PNGs (no submodules required)

---

## 📦 Upstream Repository Overview

* Upstream project: `HatScripts/circle-flags`
* Asset format: SVG
* Characteristics:

  * Very comprehensive coverage of countries / regions
  * Actively community-maintained
  * Circular visual style, suitable for clipped display

CircleFlagsKit **does not use SVGs directly**. Instead:

> **SVGs are converted into PNGs via scripts and committed as SwiftPM Resources**

---

## 🧱 Directory Structure Convention

After introducing the upstream repository, the CircleFlagsKit structure looks like this:

```
CircleFlagsKit/
├─ Vendor/
│  └─ circle-flags/        ← upstream submodule (not compiled directly)
│
├─ Sources/
│  └─ CircleFlagsKit/
│     └─ Resources/        ← PNGs actually packaged by SwiftPM
│        ├─ us.png
│        ├─ gb.png
│        ├─ ca.png
│        └─ xx.png
│
└─ Scripts/
   ├─ update_flags.sh
   └─ validate_flags.py
```

---

## 1️⃣ Add the Upstream Repository as a Git Submodule (One-time)

From the **CircleFlagsKit root directory**, run:

```bash
mkdir -p Vendor
git submodule add https://github.com/HatScripts/circle-flags.git Vendor/circle-flags
git submodule update --init --recursive
```

Commit the submodule pointer:

```bash
git add .gitmodules Vendor/circle-flags
git commit -m "Add circle-flags as upstream submodule"
```

> ⚠️ Notes:
>
> * **Do not** copy upstream files into the repo
> * Commit **only the submodule pointer**

---

## 2️⃣ Locate the SVG Source Directory (First Time Only)

The upstream repository structure may change, so you must **confirm the SVG path once**.

Run:

```bash
find Vendor/circle-flags -maxdepth 4 -name "*.svg" | head -20
```

Typical paths look like:

```
Vendor/circle-flags/flags/us.svg
Vendor/circle-flags/flags/gb.svg
```

Add this path to the script’s candidate list, for example:

```bash
SVG_DIR_CANDIDATES=(
  "Vendor/circle-flags/flags"
)
```

> ✅ This step is required **only once**
> No changes are needed unless the upstream repo significantly restructures

---

## 3️⃣ Automatic PNG Generation Script: `update_flags.sh`

### Script Responsibilities

`Scripts/update_flags.sh` performs the following:

1. Update the submodule (optional)
2. Locate the upstream SVG directory
3. Convert SVG → PNG using `rsvg-convert` or `inkscape`
4. Output PNGs to `Sources/CircleFlagsKit/Resources/`
5. Normalize:

   * Lowercase filenames
   * Two-letter country codes
   * Fixed size (e.g. 128×128)

---

### Dependencies (macOS)

```bash
brew install librsvg
```

Verify installation:

```bash
rsvg-convert --version
```

---

### Make the Script Executable

```bash
chmod +x Scripts/update_flags.sh
```

---

### Run the Generator (Example)

```bash
./Scripts/update_flags.sh 128
```

Parameters:

| Parameter | Meaning                  |
| --------- | ------------------------ |
| `128`     | Output PNG size (square) |

---

## 4️⃣ (Optional) Country Code Whitelist

If you **do not want to include all countries** (to reduce package size), you can use a whitelist.

### Create a Whitelist File

```
Scripts/allowed_codes.txt
```

Example contents:

```
# country codes (lowercase)
us
gb
ca
de
fr
jp
sg
```

Behavior:

* ✅ File exists → **only generate PNGs for whitelisted codes**
* ❌ File absent → generate PNGs for all SVGs

---

## 5️⃣ Commit the Generated PNGs (Very Important)

After generation:

```bash
git add Sources/CircleFlagsKit/Resources
git commit -m "Add generated circle flag PNG resources"
```

📌 **Principles:**

* PNGs **must be committed**
* Package consumers **do not need the submodule**
* SwiftPM depends **only on `Resources/`**

---

## 6️⃣ Standard Workflow for Upstream Updates (Long-term Maintenance)

This is the recommended **full workflow** for every future flag update:

```bash
# 1. Update submodule to latest upstream commit
git submodule update --remote --merge

# 2. Regenerate PNGs
./Scripts/update_flags.sh 128

# 3. Validate resources + run tests
python3 Scripts/validate_flags.py \
  --resources Sources/CircleFlagsKit/Resources \
  --require-fallback xx \
  --strict-alpha2

swift test

# 4. Commit & tag
git add .
git commit -m "Update flags from upstream"
git tag 1.0.1
git push --follow-tags
```

📦 App projects only need to bump the SPM version.

---

## 7️⃣ Troubleshooting (FAQ)

### Q1: The script reports that it cannot find `SVG_DIR`

The upstream directory structure has changed.

Run:

```bash
find Vendor/circle-flags -maxdepth 5 -name "*.svg" | head -20
```

Add the correct path to `SVG_DIR_CANDIDATES`.

---

### Q2: The generated PNGs are not circular?

This is **expected**.

* Upstream SVGs have a circular *visual*
* The PNG canvas is still square
* **Final circular appearance is achieved via**
  `clipShape(Circle())` in SwiftUI

---

### Q3: The package size is too large?

Possible solutions (use one or combine):

* Use `allowed_codes.txt`
* Reduce output size (e.g. 96)
* Generate only the countries your app actually needs
