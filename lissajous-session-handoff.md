# Lissajous Project — Session Handoff Context

> Paste this file's contents at the start of a new Claude Code session to continue work on the lissajous project. The active file is `index.html` in this same folder.

---

## What this project is

A single-file vanilla HTML/CSS/JS audio-visual synthesizer that draws Lissajous curves (parametric X/Y figures on a canvas) and produces matching audio via the Web Audio API. All state lives in one file: `index.html` (~4575 lines). There is no build step.

A local dev server is configured in `.claude/launch.json`: `python3 -m http.server 8765`. Open `http://localhost:8765/index.html` in a browser to test.

---

## Current feature set (as of last session)

### Signal flow
- **Carrier:** X and Y axes each have frequency ratio, amplitude, phase offset
- **FM (frequency modulation):** ratio, amount, waveform shape (sine/square/saw/tri/etc), invert-polarity checkbox per axis
- **Warp H / Warp V:** horizontal/vertical waveshaping; each has invert-polarity checkbox
- **PWM:** pulse-width modulation amount; invert-polarity checkbox
- **AM (amplitude modulation):** ratio, amount, waveform shape
- **Noise:** 0–0.10 range, adds sample-level noise
- **Filter (final stage in Synthesis):** multimode biquad (LP/HP/BP/Notch), Cutoff (expressed in harmonics, `open` = bypassed), Resonance — applied to the per-axis sample buffer, so it reshapes the figure, the wave preview, AND the audio wavetable identically
- `processWave(carrierArg, freqT, type, axis)` — per-sample chain: FM → sync → warpH → PWM → base wave → warpV → waveshape → fold → AM → noise

### Figure rendering
- Canvas 2D rendering of the Lissajous curve
- **Dots ↔ Line slider** (`params.dotsLine`): at max = continuous line; lower = dots (visual sample-size reduction)
- **Phase rotates FM/AM modulators checkbox** (`phaseModulators`): when on, the carrier's phase offset also offsets FM and AM modulator phases
- Background color covers entire page (not just canvas)
- **Construction view** (`drawMode4`, `constructionView`): figure-tracing animation with X/Y wave strips, projection lines, and a bright trail. **Active by default on startup.** As of this session `drawMode4` builds **filtered** per-axis sample arrays (`_m4BufX`/`_m4BufY`) and applies the multimode filter with the same normalized cutoff as `drawLissajous`, so the construction view now reflects EVERY waveform stage (filter, sync, warps, PWM, fold, AM, noise) identically to the main view. Two sliders (shown only when construction view is on):
  - **Trace tempo** (`params.traceSpeed`): speed the figure is traced, independent of the phase-animation speed (`animSpeed`). Drives `mode4T` advance.
  - **Untraced opacity** (`params.untracedAlpha`, 0–1): opacity of the dim not-yet-traced background figure.

### Audio
- Internal generator: builds a `PeriodicWave` from DFT of `processWave` samples → `OscillatorNode` per axis → stereo panning → master gain
- **External audio input:** `getUserMedia` → `MediaStreamAudioSourceNode` → analyser → gain → master gain. Exclusive switch (internal OR external, no mixing)
- **Monitoring toggle**: routes master to `AudioContext.destination`
- **IN meter**: shows RMS level of external input
- **`↻ reset audio engine` button** (`resetAudioEngine`): full teardown + rebuild of the Web Audio graph against the *current* system devices, then recaptures the selected input. Reliable recovery when the engine wedges after a macOS in/out device change.
- **`grant access & list devices`** also re-establishes capture when in EXTERNAL mode (not just re-lists). `connectExternalInput` rebuilds a `closed` context and resumes a `suspended` one.
- **MediaRecorder** for video: canvas stream + audio track. **Records from the Web Audio tap (`recDest`) for BOTH internal and external** — external feeds masterGain → recDest. (Recording the raw getUserMedia track directly produced silent external recordings in Chrome once the track was also consumed by the AudioContext + the muted `<audio>` pump; recDest is taken before the monitor mute so recordings still contain audio with monitoring off. External record level follows the Monitor-level slider, so keep it > 0.) **Frame-preview overlay hidden by default on startup** (`recShowFrame = false`).
- **WAV export**: single-cycle waveform export button. **Tuned to C0** (≈16.35 Hz): 2048-sample frame written at `SINGLE_CYCLE_SR = round(2048 × C0_HZ) = 33488 Hz`, so the cycle's natural fundamental is C0. Filename tagged `_C0`.
- Wave preview display above WAV export (responsive width)

### MIDI
- CC mapping system with learn mode, slew interpolation (`MAP_SLEW_TAU`)
- `MAP_TARGETS` / `MAP_DEFAULTS` / `midiMappings`
- MIDI note input and base frequency are in the Frequencies section
- CC mapping input is at the top of the CC Mappings section
- **Preset-grid pads** are MIDI-addressable: note-ons on `gridChannel` (settable 1–16) from ANY connected input → load the pad at `note − GRID_BASE_NOTE`. Handled in `onMidiMessage` before the note-device gate.

### LFOs
- Two LFOs, each with wave/rate/depth/retrigger + assignable targets (`lfos[]`, `buildLFOPanels`, `renderLFOTargets`).
- Transient apply/restore model: `applyLFOs()` writes modulated values into `params` before draw, `restoreLFOs()` reverts after; the wavetable is rebuilt while values are live (`pwTick`). This means LFO targets are limited to **params-backed continuous keys the figure/wavetable actually read** — NOT audio-node-only params (volume, pitch) or color.
- Target set (`LFO_TARGET_OPTIONS` / `VEL_RANGES`) expanded this session to: fmAmount, **fmRatio**, shapeAmt, pwAmount, amAmt, **amRatio**, foldDrive, warpH, warpV, syncAmt, noiseAmt, **filterCutoff**, **filterQ**, ax, ay, phase, lineWidth, **dotsLine**, **traceSpeed**, **untracedAlpha**. `LFO_SYNTH_KEYS` (keys that trigger continuous wavetable rebuild) gained fmRatio/amRatio/filterCutoff/filterQ.

### Evolve (parameter mutation) — `section-evolve`, below LFOs
- **Mutate** button randomises every *included* parameter toward a random in-range value by the **Deviation** amount (`evolve(amount)`); deviation 1 = fully random, 0 = unchanged (lerp current→random).
- Reuses **`MAP_TARGETS`** as the master mutable-parameter registry (`EVOLVE_KEYS = keys minus 'preset'`), so anything CC-mappable is evolvable. `readTarget(key)` mirrors each target's value; `setTargetValue` applies.
- Per-parameter include checkboxes (`evolveInclude`, `buildEvolveList`), **select all / deselect all** (`setAllEvolve`). Default-OFF: constructionView, animatePhase, visualSwap, volume (`EVOLVE_DEFAULT_OFF`).
- **Reset to defaults** (`evolveReset`): `resetAll()` + restores animSpeed/LFO rates+depths/volume.

### Session preset grid (right sidebar)
- Toggle: **`PRESETS`** button in the header (`grid-toggle`); folds the right sidebar via `.layout.grid-hidden`. **Folded by default.**
- **4×16 = 64 pads** (`GRID_PADS`). Each pad stores a full patch (`serializePreset()` snapshot); loading calls `applyPresetData()`.
- **LOAD / STORE mode toggle**: click loads (LOAD) or stores current patch into the pad (STORE). **Right-click clears** a pad.
- Pads addressable from **C1** (`GRID_BASE_NOTE = 24`), pad i → note 24+i. All 64 pads (C1–D#6, notes 24–87) are within MIDI range — no click-only pads.
- **Pad color = the stored patch's line color** (`params.strokeColor`); label text auto-contrasts (black/white by luminance).
- **Export / import** the whole grid as JSON (`exportGrid` / `importGrid`): `{ app:'lissajous-grid', version:1, baseNote, channel, presets[] }`. Grid is session storage, separate from the single-patch save/load.
- State: `gridPresets[64]`, `gridChannel`, `gridStoreMode`, `gridActiveIdx`. Build: `buildGrid` / `renderGrid` / `renderGridPad`.

### UI
- Collapsible sidebar sections (cards)
- Left sections: **Synthesis, Frequencies, Audio, Figure, Video, LFOs, Evolve, CC Mappings**
- **Synthesis order** (reorganised this session): X/Y wave + WAV export → **AM** (moved to top) → FM → Waveshape → Drive(fold) → Noise → Filter → **"Warp & Sync" subsection** (PWM, Warp H, Warp V, Sync) → **"Patch" subsection** (export/import `preset-save`/`preset-load`, moved here from Frequencies) → Reset All. Frequencies keeps the ratio preset grid ("Ratio Presets").
- 280px left sidebar, no horizontal scroll. Right preset sidebar is 196px (`.preset-sidebar`), folds away.
- Page background color controlled by color picker (sidebar panel color unaffected)
- FM/AM ratio sliders snap to 31 specific simple fractions: 1/2, 2/3, 1/1, 4/3, 3/2, 5/3, 2/1, 7/3, 5/2, 8/3, 3/1, 10/3, 7/2, 11/3, 4/1, 13/3, 9/2, 14/3, 5/1, 16/3, 11/2, 17/3, 6/1, 19/3, 13/2, 20/3, 7/1, 22/3, 15/2, 23/3, 8/1

---

## Key code landmarks

| What | Where |
|------|-------|
| `params` object | near top of `<script>` |
| `processWave(carrierArg, freqT, type, axis)` | synthesis core |
| `drawLissajous()` | builds sxArr/syArr, applies filter, renders line or dots |
| `drawWavePreview()` | renders wave preview above WAV export |
| `buildPeriodicWave(type, axis)` | samples processWave → DFT → PeriodicWave for Web Audio |
| Filter helpers | `filterType`, `filterHarmonics()`, `filterIsOn()`, `biquadCoeffs()`, `filterPeriodic()` |
| `phaseModulators` | module-scope boolean; toggled by checkbox |
| `params.dotsLine` | 0=dots, 1=line |
| `startAudio()` | builds Web Audio graph |
| `connectExternalInput(deviceId)` | getUserMedia, connects external source; rebuilds dead/suspended context |
| `requestPermissionAndList()` | enumerate-while-stream-live pattern |
| `resetAudioEngine()` | full teardown + rebuild + recapture (the `↻ reset audio engine` button) |
| `RATIO_LABELS`, `RATIO_STEPS` | 31-entry fraction arrays for FM/AM ratio sliders |
| `drawMode4(ctx,w,h,phase)` | construction view; builds filtered `_m4BufX/_m4BufY`; advances `mode4T` by `params.traceSpeed`; untraced figure alpha = `params.untracedAlpha` |
| `evolve(amount)` / `evolveReset()` | Evolve mutate + reset |
| `EVOLVE_KEYS`, `evolveInclude`, `readTarget(key)`, `buildEvolveList`, `setAllEvolve` | Evolve registry + UI (reuses `MAP_TARGETS`) |
| `LFO_TARGET_OPTIONS`, `VEL_RANGES`, `LFO_SYNTH_KEYS` | LFO target list / ranges / wavetable-rebuild keys |
| recording audio track | `startRecording` taps `recDest` (Web Audio) for internal AND external |
| `buildGrid` / `renderGrid` / `renderGridPad(i)` | preset-grid sidebar build + per-pad render |
| `storeGridPad` / `loadGridPad` / `clearGridPad(i)` | pad store / load / clear |
| `exportGrid` / `importGrid(obj)` | grid JSON export / import |
| `GRID_PADS`, `GRID_BASE_NOTE`, `gridChannel`, `gridPresets[]`, `gridStoreMode`, `gridActiveIdx` | grid state |
| `SINGLE_CYCLE_SR`, `C0_HZ` | single-cycle WAV sample rate tuned to C0 (=33488 Hz) |
| `params.traceSpeed`, `params.untracedAlpha` | construction-view sliders (serialized in patches) |
| `.claude/launch.json` | python http.server on port 8765 |

---

## Known issues / ongoing

### External audio input — device-switch breakdown
**Root cause:** an `AudioContext` binds to the system **output** device at creation, and a captured input stream gets invalidated when macOS changes *either* the default in or out device underneath it. Re-granting permission does NOT fix an already-dead/wedged context — only a full rebuild does. Separately, on `file://` Chrome withholds device labels/IDs (returns `"Input 1"`) and may capture the wrong device.

**Mitigations in the code (as of this session):**
- `↻ reset audio engine` button → `resetAudioEngine()`: full teardown + rebuild against current devices + recapture. The reliable recovery.
- `grant access & list devices` now also recaptures when in EXTERNAL mode.
- `connectExternalInput` nulls a `closed` context (forces rebuild) and resumes a `suspended` one.
- EXTERNAL IN captures immediately on click; `file://` warning shown if `location.protocol === 'file:'`.

**Troubleshooting steps (in order) if it still misbehaves:**
1. Set BlackHole as system default **output first, then input** (System Settings → Sound) *before* enabling page audio — the context picks up whatever output is default at build time.
2. In the page: **EXTERNAL IN** → **↻ reset audio engine**. Watch the **IN meter** — moving = signal reaching Web Audio (monitor + record will too).
3. Meter dead? **grant access & list devices** → pick BlackHole by name → **↻ reset audio engine** again.
4. Still broken? **Reload the page (Cmd-R)** — nuclear reset, disposes every audio object. Then redo 1–2.
5. **Sample-rate mismatch:** BlackHole defaults to 48 kHz; if output (speakers) is 44.1 kHz, set both to the same rate in **Audio MIDI Setup** (48000). Mismatched rates → silent-but-connected captures in Chrome.
6. **Serve over http**, not `file://`: `python3 -m http.server 8765`, open `http://localhost:8765/index.html`. On `file://` Chrome hides device names. Safari exposes names on `file://`.
7. **Diagnostic line** under the meter shows `track: live/ended` + `(muted by OS)`. `ended`/`muted by OS` = OS killed the track → reset (2) or reload (4); re-granting won't revive that track.

**Mental model:** meter moving = good (everything downstream works); meter dead but device connected = OS/device problem → reset engine → reload → check sample rates.

**Cannot be tested in Claude's sandbox** (getUserMedia returns `NotAllowedError: Permission denied` in headless env).

---

## Files
- `index.html` — **active working file**, all changes go here
- `.claude/launch.json` — dev server config

---

## User preferences / working style
- Single-file HTML approach, no build tooling
- Prefers terse responses, no trailing summaries of what was just done
- New major features (like audio input) get saved to a new file with a descriptive name suffix; incremental improvements go in the current file
- Uses BlackHole for DAW-to-browser audio routing on macOS
- Tests in both Chrome and Safari; Chrome is problematic for audio device enumeration on file:// origins
