# Design amendment — Psychological layer, Fitbit default sensor, PC lab MVP

**Programme:** BattleMed (CONTAI) · MedPod + MVP app  
**Date:** 6 September 2026  
**Hold:** **72 hours** (rescoped from 168)  
**Status:** Design amendment for engineering review — not clinical authorisation

Derived from D1 doctrinal psych anchors **KR-07** (extraction is recurring, not terminal) and **KR-08** (nursing schedule is morale architecture), and from the gap that suicide / psych deterioration has no CPG. This document does **not** invent therapy or crisis-hotline UI that claims clinical treatment.

---

## 1. Psychological-layer goals

| Goal | Meaning in product |
| --- | --- |
| Preserve agency | Casualty chooses outcomes; app never shames or pathologises |
| Routine continuity | Nursing and check cadence continue after failed extraction |
| Hope under failed extraction | Next attempt remains possible; clock does not reset |
| Detect cognitive drift | Timed micro-task vs **personal** baseline; deltas only |
| Never pretend to be a therapist | Fixed spoken strings; no open chat therapy; no diagnosis |

The psychological layer is **continuity architecture**, not a mental-health product. It sits beside clock + ledger. Language proposes; Swift commits. Calculation firewall unchanged: no dose arithmetic, no unsupervised clinical decisions in the model.

---

## 2. Six concrete app artefacts

### 1 — Nursing-as-morale schedule (KR-08)

One artefact covering reposition, ankle pumps, and oral care. Calm copy. The schedule **is** the morale architecture: body care keeps agency and dignity under prolonged hold. Oral care gate: every ~12 h. Reposition remains q1–2 h nursing.

### 2 — Extraction attempts log (KR-07)

Extraction is a **recurring** event, not a terminal climax. Log attempt + outcome (failed / succeeded / deferred). Failed attempt:

- does **not** reset the 72 h mission clock  
- does **not** shame  
- spoken line (fixed): next attempt remains possible; continue the schedule  

### 3 — Timed cognitive micro-task vs personal baseline

Simple timed task (serial subtract / digit-style). Baseline stored once at first successful check (mission start window). Later scores store **latency + correctness deltas only**. No diagnosis labels, no “cognitive impairment” claims.

### 4 — Presence check-ins (procedural, not therapy)

Closed prompts such as “name three things you can feel” / “next gate”. Voice uses **fixed spoken strings** only — never LM-generated clinical or psych content.

### 5 — Missed-check framing (existing)

Keep as **deterioration signal**, soft language. Overdue checks are clinical signal in isolation, not nagging.

### 6 — Night / dark UI

Screen-off rest already exists. Deep-red theme. Psychological layer must **not** add bright animations, unsolicited cheerfulness, or autonomous screen wakes (signature discipline on field phone).

---

## 3. Hard rules

- **No** suicide-risk scoring claims  
- **No** “AI companion” romance or parasocial framing  
- **No** unsupervised psych diagnosis  
- **Provenance tags** for sensor vs self-report (`Wearable-derived` vs `Casualty-entered` / `Device-measured`)  
- **Calculation firewall** intact — model does language only; Swift owns timers, scores, commits  
- **Do not** invent crisis-hotline / therapy UI that claims to treat psych deterioration (no CPG exists for this gap)

---

## 4. Fitbit as MedPod default monitoring sensor (MVP)

| Item | MVP position |
| --- | --- |
| Default trend source | Consumer Fitbit (or equivalent) BLE heart-rate for demo trends |
| SpO₂ | **Never** clinical logic; loss of signal is a **finding**, never imputed |
| Session shape | Scheduled ≤60 s foreground (or PC session) — not continuous locked HealthKit polling |
| Phone field path | Scheduled foreground BLE; HealthKit remains constrained / locked-store risk |
| **PC / lab path** | Web Bluetooth / Fitbit device BLE or USB dongle — **bypasses iOS HealthKit** for lab MVP |

Self-measures remain load-bearing: pulse count, urine volume, radial pulse Y/N, timed cognitive vs baseline. Wearable HR is trend input when paired; self-count is not replaced.

---

## 5. Gaming PC / equivalent as MVP target

| Path | Role |
| --- | --- |
| **Gaming PC / equiv** | Allowed for psych + sensor + local-LLM **lab** MVP |
| **iPhone** | Remains field form-factor candidate |
| Shared | Ledger schema shared across platforms |
| Model | PC may run heavier local model; phone stays memory-tier constrained |
| Emissions | Signature discipline applies to **field phone**, not lab PC |

Target device for programme demos: **iPhone 17 Pro Max OR gaming PC / equivalent (lab MVP)**.

---

## 6. Hold duration

**72 hours everywhere** — presentation, specs narrative, and app `MissionClock.holdMinutes = 72 * 60`. Antibiotic prophylaxis window and PCC working ceiling remain aligned to this rescope.

---

## 7. Implementation notes (app)

- Gates: `cognitive` (q6–8 h), `oral` (q12 h), reposition (nursing), existing clinical gates  
- Cards: `cognitive`, `oral`, `extraction` with non-shaming outcomes  
- Cognitive flow: 30 s serial task in Swift only; baseline in UserDefaults  
- Spoken psych continuity strings: fixed bundle text only  

---

*End of amendment · BattleMed (CONTAI) · 6 Sep 2026 · 72 h*
