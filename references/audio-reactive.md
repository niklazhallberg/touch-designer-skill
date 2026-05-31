# Audio-reactive systems in TouchDesigner

> **Trigger:** when the task involves audio-driven visuals, audio input, frequency analysis, or beat/tempo detection — load this file. **And remember the BlackHole routing for system audio on Mac** (§ "Mac routing"). Use the bold CHOP names below as grep anchors when you're stuck on a specific operator.

---

## Input — Audio Device In CHOP, Audio File In CHOP, Audio Device Out CHOP

**Confidence:** HIGH (TD-documented)

### **Audio Device In CHOP**

The live-audio entry point. **Use "frames" mode for low-latency audio-reactive work** — buffer-based modes introduce extra delay between sound and visual.

- Selects the input device (system default or named device — see § "Mac routing" for routing system audio)
- Channel count + sample rate exposed; TD CHOPs run at the device's native sample rate downstream of this op
- "Frames" sample-mode minimizes buffering; pick this for show-time reactivity

### **Audio File In CHOP**

Plays an audio file (`.wav`, `.aif`, `.mp3`, etc.) into the CHOP graph. Used for:
- Preview/testing audio-reactive patches without a live source
- Pre-rendered audio in installations where the track is fixed
- Show-rig where a file plays as the master and is *both* analyzed and routed to the speakers (see canonical show rig below)

### **Audio Device Out CHOP**

Routes a CHOP signal to a hardware audio output. Closes the loop when TD is the audio host as well as the visual host.

### Canonical show rig

```
[Audio File In] ──┬─→ [analysis chain: Spectrum / Analyze / smoothing] → [visuals]
                  └─→ [Audio Device Out] → speakers
```

One source, split into two consumers. The analysis chain and the audio-out chain operate on the same signal — they cannot drift, the visuals always match what the audience hears.

---

## Frequency analysis — Audio Spectrum CHOP, Audio Analyze CHOP

**Confidence:** HIGH (TD-documented)

### **Audio Spectrum CHOP**

FFT-based frequency analysis. Output is N bins of magnitude per audio channel.

- Parameter surface includes FFT size and window function
- Output is per-bin magnitude — direct bins are useful for graphic-EQ-style visuals but **jitter heavily** at the bin level
- For stable visual mapping: aggregate adjacent bins into band averages (see § "Band patterns")

### **Audio Analyze CHOP**

Scalar audio metrics rather than spectrum bins. Typical outputs include **RMS**, **peak**, and **spectral centroid** (perceived brightness).

- One value (or a few) per audio channel per cook — much cheaper than spectrum
- Use for amplitude-following visuals (envelope, loudness mapping) when you don't need frequency content
- Pair with Audio Spectrum CHOP when you want both "how loud" and "what frequencies"

---

## Rate-gap mental model — audio rate vs visual cook rate

**Confidence:** HIGH (TD-documented architecture)

TD's audio CHOPs run at the device's **audio rate** (typically 48 kHz). TD's visual cook runs at **60 Hz** (or 30 / 120 / project-configured). These rates are 800× apart.

**Hard rule: audio-rate signal NEVER reaches a shader or POP directly.** It must be resampled and smoothed to cook-rate first, otherwise:
- The shader/POP cooks at 60 Hz but receives 48000 samples per second — only 1 in 800 ever lands
- The 1-in-800 you happen to land on aliases hard; the visual flickers

### Canonical rate-bridge

```
[Audio @ 48 kHz] → [Spectrum/Analyze @ 48 kHz] → [Resample CHOP @ 60 Hz]
                                                       │
                                                       ↓
                                                  [smoothing]
                                                       │
                                                       ↓
                                                  [shader / POP / instance count]
```

**Resample CHOP** is the explicit rate-change point. After this, the signal is cook-rate and safe to drive visuals.

### CHOP → GLSL uniform binding

Use the **vec4-via-Vectors-page** pattern (same as the absTime uniform — see `glsl-patterns.md`): expose a custom vec4 uniform on the `glslMAT` or `glslTOP`, bind component(s) to CHOP value expressions like `op('audio_band_low')['chan1'][0]`. The shader reads `uMyAudio.x` as a per-cook float, sampled at visual rate.

---

## Mac routing — BlackHole (CRITICAL)

**Mac-critical** | **Confidence:** MEDIUM (community practice, not officially documented by TD; widely-used standard)

> **The single most common Mac trap for audio-reactive visuals.** Without this, "use Spotify as the audio source" doesn't work — TD can't see another app's audio.

### The problem

macOS doesn't expose system audio (Spotify, Ableton, Logic, etc.) as a microphone-style input device. `Audio Device In CHOP` can read the system microphone or a USB interface, but not "whatever audio is playing through the speakers."

### The solution: BlackHole

**BlackHole** is a free, open-source virtual audio device for macOS. Install it, then set up a **Multi-Output Device** in `Applications → Utilities → Audio MIDI Setup`:

1. Install BlackHole (16ch is the common variant): [existential.audio/blackhole](https://existential.audio/blackhole)
2. Open **Audio MIDI Setup → Create Multi-Output Device** combining your normal output (speakers/headphones) + BlackHole
3. Set the Multi-Output Device as the system output
4. In TD, point `Audio Device In CHOP` at **BlackHole**

Result: Spotify (or Ableton, or any system audio) plays to your speakers AND streams into BlackHole, which TD reads as a regular input.

### Alternatives (less common in 2026)

- **Loopback** (Rogue Amoeba, paid) — more flexible routing, GUI-driven
- **Soundflower** — older, less maintained; check current status before recommending
- **Audio Hijack** (Rogue Amoeba) — capture-from-specific-app workflows

**Default recommendation:** BlackHole + Multi-Output Device. Free, established, works on Apple Silicon.

---

## Band patterns — bins vs band-averages

**Confidence:** MEDIUM (community practice)

Audio Spectrum CHOP outputs N bins (typically 64–512). Two ways to consume:

### Direct bins (graphic-EQ-style)

- Channel N drives bar/element N directly
- **Jitters heavily** — adjacent bins have very different magnitudes and individual bins fluctuate fast
- Use for: spectrum-visualization where the jitter IS the aesthetic (waveform/bars visuals)
- Don't use for: smooth/musical visual response

### Band averages (recommended for most reactive work)

Aggregate adjacent bins into **3–16 stable bands**, average their magnitudes. Typical splits:

| Band | Frequency range | Typical use |
|---|---|---|
| **Low** | 20 – 150 Hz | Kick, bass, sub — drives "heavy" visuals (scale, weight) |
| **Mid** | 150 – 2000 Hz | Vocals, mid-frequency instruments — drives "presence" visuals |
| **High** | 2 – 12 kHz | Cymbals, hi-hats, air — drives "sparkle" visuals |

### Implementation

After Audio Spectrum CHOP:
- **Select CHOP** picks the bin range for one band
- **Math CHOP** in average mode collapses those bins to a single magnitude
- Repeat per band, **Merge CHOP** into a single multi-channel band-summary CHOP

For more granularity: 8 or 16 bands using log-spaced frequency boundaries (mimics human pitch perception).

### Decision rule

- **2-16 channels of stable music-following response** → band averages
- **Visualizer-style spectrum display where bin-level activity IS the visual** → direct bins
- **Default** when in doubt → band averages (3-band low/mid/high is the workhorse)

---

## Smoothing — asymmetric attack/release (the "liquid" feel)

**Confidence:** MEDIUM (community practice, core to the smooth/musical aesthetic) | **Cross-link:** relevant for particle-system-driven visuals

The single most important shaping move for audio-reactive visuals. Without it, response feels twitchy/digital. With it, response feels smooth, organic, "liquid."

### Asymmetric smoothing via **Lag CHOP**

Lag CHOP has separate **attack** (rise) and **release** (fall) filter widths. **Attack faster than release.**

| Parameter | Typical range | Why |
|---|---|---|
| **Filter Width Up** (attack) | 5 – 30 ms (beat-driven content); up to 50 ms for sub-bass | Fast attack so beats land sharp |
| **Filter Width Down** (release) | 150 – 500 ms | Slow release so the visual decays musically instead of snapping back |

For music with prominent transients (kicks, snares): attack ≈ 10 ms, release ≈ 200-400 ms.

For ambient / pad-heavy music: attack and release both slower (50 ms / 800 ms+) — match the source material's envelope shape.

### Rule

**Lag CHOP with asymmetric width is the default first stage after band aggregation.** Insert it before any threshold/round/hysteresis logic downstream. If response feels "twitchy," your release is too short. If response feels "laggy on beats," your attack is too slow.

---

## Anti-jitter — round-then-smooth, hysteresis

**Confidence:** MEDIUM (community practice)

When mapping to **integer visual parameters** (instance count, octave, grid resolution, particle count), continuous audio values produce flicker at threshold crossings. Two patterns:

### Round-then-smooth (for instance counts)

1. Smooth the audio band first (Lag CHOP, asymmetric — see above)
2. Math CHOP with floor/round to integer
3. **Then** a second Lag CHOP to smooth the *quantized* output (prevents single-frame jumps)

Pattern: continuous-smooth → quantize → discrete-smooth.

### Hysteresis (for state changes)

When a parameter has discrete states (low/high, gate open/closed, mode A/mode B), use **two thresholds + Logic CHOP**:

- Threshold UP at e.g. 0.7 (transition low → high)
- Threshold DOWN at e.g. 0.5 (transition high → low)
- **Logic CHOP** holds the state until the opposite threshold is crossed

The 0.2 hysteresis gap absorbs noise around the trigger point. Without hysteresis, a signal hovering near the threshold flickers state every frame.

---

## Beat detection — Audio Beat CHOP does NOT exist; build it

**Confidence:** HIGH (the negative — Audio Beat CHOP confirmed not in TD)

> **Known gap (confirmed empty):** there is **no Audio Beat CHOP** in TD 2026-05. Don't search the palette for one. Beat detection is built from primitives OR sourced from a DAW.

### Heuristic beat detection (built from CHOPs)

When no DAW is in the loop:

```
[Audio Spectrum] → [Select low-band bins] → [Math: avg] → [Lag asymmetric]
                                                              │
                                                              ↓
                                                       [Math: threshold]
                                                              │
                                                              ↓
                                               [Logic CHOP: Off Delay (refractory)]
                                                              │
                                                              ↓
                                                       [beat pulse channel]
```

Key parameters:
- **Threshold**: tuned per source (loud music = higher, quiet = lower; for headroom, normalize first)
- **Refractory period (Off Delay)**: 100–250 ms — prevents double-triggering on a single kick. Tempo-dependent: 250 ms ≈ 240 BPM max.

Tune by eye: trigger should land on the kick, not retrigger on the kick's tail, not miss the next kick.

### Ableton Link CHOP (preferred when Ableton is in the loop)

**Ableton Link CHOP** reads **tempo / beat / phase** from any Link-enabled app on the network. When a DAW or Link-aware app drives the show, this is more accurate than heuristic detection because the source IS the canonical timing.

- Output channels: tempo (BPM), beat (running beat count), phase (0–1 within the bar)
- No latency from analysis — Link is a sync protocol, not a detector
- Choose this whenever Ableton (or another Link-aware tool) is the source

**Default rule:** Ableton Link > heuristic. Use heuristic only when the audio source has no Link option (recorded music, live mic, etc.).

---

## CPU / GPU characteristics

**Confidence:** HIGH (TD-documented architecture)

- **Audio analysis in TD is CPU-bound** — there is no GPU-based audio analysis. Audio CHOPs and Spectrum/Analyze CHOPs run on the CPU.
- **Cost scales with FFT size:** a 4096-point FFT costs proportionally more than 1024-point. At very high FFT sizes (8192+) on heavy chains, audio becomes a measurable hotspot.
- **On M1 Pro / Apple Silicon, audio is rarely the visual-budget bottleneck.** Default FFT sizes (1024–2048) cost very little relative to a real visual chain (POPs, GLSL, render passes).
- **No native NDI audio in TD** (as of 2026-05) — audio-over-network goes through OSC + manual buffering, or via NDI's video channel as a hack.

---

## Known gaps — operators that DON'T exist (confirmed empty)

These are publicly **confirmed not present** in TD as of 2026-05-31. Don't search the palette for them. Build the functionality from CHOP primitives instead, or accept that TD doesn't ship it.

| Operator name (DOES NOT EXIST) | What to build instead |
|---|---|
| **Audio Beat CHOP** | Spectrum → low band → Lag asymmetric → Threshold → Logic (Off Delay refractory). See § "Beat detection". |
| **Audio Band Filter CHOP** | Spectrum → Select bins per band → Math (average mode). See § "Band patterns". |
| **Audio Band EQ CHOP** | Same as above — pre-built band-EQ pipeline doesn't exist. |
| **Audio Envelope CHOP** | Math (abs) → Lag asymmetric. Or use RMS via Audio Analyze CHOP if it exposes RMS. |
| **Audio Stream In CHOP** | Use Audio Device In + virtual audio routing (BlackHole on Mac, VB-Audio on Windows). |
| **Native NDI audio receiver** | Route audio via OSC, or use the NDI video stream's audio channel via external tooling. |

**Rule:** if the agent finds itself looking for one of these operators in the palette, **stop and check this list** — TD never shipped them. The recipe is in this file.

### Other known gaps (production capture territory)

| Gap | Where it surfaces |
|---|---|
| Exact M1 audio-to-visual latency (forum estimates exist but aren't TD-verified numbers) | First time you measure it for a show with a tight sync requirement |
| Real-world FFT-size sweet spots for specific genres / use cases | First time you tune a reactive system for a specific source material |
| Whether Audio Analyze CHOP exposes spectral flux / onset detection in 2025+ | First time you try to detect onsets without writing it from scratch |

When these resolve in real work and survive the growth-protocol gates, they move into the appropriate section above.
