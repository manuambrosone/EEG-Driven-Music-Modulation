# EEG-Driven-Music-Modulation
A neuroscience-art project in which EEG activity recorded during music listening dynamically modulates the mix of the same song inside Ableton Live.
---

## Overview

This project transforms neural oscillations into audio-control signals.

The EEG recording is processed in MATLAB and converted into low-frequency control envelopes used inside Ableton Live to modulate:

- drums
- synthesizers
- piano layers
- spatial effects

The result is a brain-modulated reinterpretation of the original song.

---

## Pipeline

EEG Recording
→ EEG preprocessing
→ Frequency-band extraction
→ Feature extraction
→ Baseline normalization
→ WAV control signals
→ Ableton Live modulation

---

## EEG Bands

| Band | Function | Audio Mapping |
|---|---|---|
| Theta | Immersion / depth | Reverb |
| Alpha | Relaxation / stability | Piano |
| Beta | Attention / engagement | Drums |
| Gamma | Perceptual detail | Synth brightness |
| Energy | Global activation | Mix intensity |

---

## Requirements

- MATLAB
- EEGLAB
- Signal Processing Toolbox
- Ableton Live

---

## Usage

Run:

```matlab
eeg_to_ableton_control
```

The script exports:

- alpha_control.wav
- beta_control.wav
- gamma_control.wav
- theta_control.wav
- energy_control.wav

These files can be used in Ableton Live through Envelope Followers.

---

## Author

Manuel Ambrosone
