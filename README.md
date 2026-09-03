# MedicalAI — native iOS app

**v0.1.0** · [juntunen-ai/MedicalAI](https://github.com/juntunen-ai/MedicalAI)


Deliverable 3 MVP spine as a real SwiftUI app: the clock, the ledger, outcome-gated
protocol cards with spoken read-back, and the handover packet.

## Run it

1. Open `MedicalAI.xcodeproj` in Xcode 16 or later.
2. Select the **MedicalAI** scheme and your iPhone as the destination.
3. Signing & Capabilities → set **Team** to your Apple ID and change the bundle
   identifier from `com.example.medicalai` to something unique.
4. Run. On the phone, Settings → General → VPN & Device Management → trust the
   developer certificate.

A free Apple ID gives a 7-day provisioning profile; re-run from Xcode to renew.
A paid account gives a year.

If the project file ever gets out of step, `project.yml` regenerates it with
XcodeGen (`brew install xcodegen && xcodegen generate`).

## What is real

- **Speech output.** `AVSpeechSynthesizer` reads the protocol cards and the
  handover packet aloud, verbatim from the bundle, with the source and version
  on screen. This is the demonstrable "voice gives instructions" path.
- **The clock.** Gates are evaluated in plain Swift and sorted by urgency. The
  tourniquet gate hard-locks past 6 h rather than offering a choice.
- **The ledger.** Append-only, checkpointed to disk with
  `.completeFileProtection` on every write, and it survives relaunch. Elapsed
  mission time is anchored to a stored origin date, so an unannounced power-off
  does not lose the timeline.
- **The handover.** ATMIST rendered from the live ledger, with a QR code
  generated on device by Core Image. Nothing is transmitted.
- **Haptics** on gate taps and outcome confirmations.

## What is stubbed, and why

`VoiceService.transcribe()` throws `transcriberNotConfigured`, and dictation
degrades explicitly to touch entry with a visible "degraded capability" notice
plus a sample transcript, so the layer hand-off stays demonstrable.

This is deliberate. `SFSpeechRecognizer` is not an option — Apple's documentation
says not to send health data through it, and it carries a one-minute limit and
per-device daily throttling. The production path is `SpeechAnalyzer` +
`SpeechTranscriber` with `SpeechDetector` for voice-activity gating and
`SFCustomLanguageModelData` for the medical lexicon. That is the single
integration point, commented in place.

The status chip reads "GEMMA · ON-DEVICE" when voice is armed. No weights ship
in this build — wiring an actual local model (MLX, or own weights inside a
Foundation Models session) is the next step, and the calculation firewall means
it may only ever structure language: it must not compute, compare, decide, or
originate clinical content.

## Structure

| File | Role |
|---|---|
| `ProtocolBundle.swift` | Signed, versioned doctrine content. Fixed doses only, no arithmetic. Ships as a signed data file in production. |
| `MissionClock.swift` | Gate state machines. All comparison and timing, deterministic. |
| `LedgerStore.swift` | Append-only store, durable before the UI acknowledges. |
| `VoiceService.swift` | Speech out; the transcriber integration point; candidate extraction. |
| `ClockScreen.swift` | Clock, gate rows, outcome cards. |
| `VoiceScreen.swift` | The calculation firewall stated on screen; read-aloud; dictate → candidate → commit. |
| `HandoverScreen.swift` | ATMIST, QR, buddy-contact list, dead-man trigger. |

## Before this becomes a product

Two gates from §13 of the specification, neither technical:

1. **Who publishes it.** Dosage calculators must come from an approved entity.
   This build ships fixed-dose reference cards and no calculation, which keeps
   it shippable, but the question governs everything about dosing.
2. **EU MDR classification.** Software driving treatment decisions is very
   likely a medical device, probably Class IIa or IIb. Establish this before the
   architecture is frozen.

Enterprise or MDM distribution avoids App Review. It does not avoid FDA, EU MDR,
or the underlying clinical-safety obligation.

Fonts: the design system specifies Archivo. Add the `.ttf` files to the target,
declare them in the Info tab under "Fonts provided by application", and swap the
two helpers in `Theme.swift` for `.custom("Archivo-...")`.
