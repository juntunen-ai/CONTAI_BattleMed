# BattleMed (CONTAI) MedPod + App — PoC Annotated Spec

**Meta:** Proof of Concept (PoC) · 72 h hold · BattleMed (CONTAI) / Harri Juntunen · App Store / MDR / distribution **out of scope for now**.

**Date:** 6 September 2026  
**Primary artefacts:** D1 Lone Casualty Knowledge Model · D2 MedPod Hardware Baseline · D3 MVP Application Spec · psych/Fitbit amendment · powered BOM/kit note · presentation PoC briefing.

---

## How to read this document

Each requirement is stated as four fields:

| Field | Meaning |
| --- | --- |
| **What** | The requirement or design choice |
| **Why it matters** | Physics, clinical, or governance rationale in plain language |
| **Source** | D1 / D2 / D3 tag, KR id, amendment, or KB cite |
| **PoC implication** | What we build or measure now vs defer |

---

## Provenance note (honest)

- **Combat-casualty physics & doctrine rationale** come primarily from programme Deliverables **D1** (lone casualty), **D2** (MedPod hardware), **D3** (app) under programme deliverables D1–D3 (see this folder and CONTAI_BattleMed).
- The Obsidian Knowledge Base (`wiki/concepts/healthcare-science` and linked sources) has **no MedPod / TCCC notes**. It informs **patient-facing AI governance, evidence/trust gaps, RPM, and Finnish SOTE pilot culture**. Cite KB only where that applies — do **not** pretend the KB contains TCCC.
- Ukraine modular-pod PDF (if present in Downloads): skipped unless separately readable and relevant; modular enclosure logistics already covered via CONTAI / AutoLoader claims in D2.

---

## 1. Mission frame

### 1.1 Seventy-two-hour PCC window

- **What:** Hold from point of injury is **72 hours** — conscious, self-treating, alone; occasional buddy contact; inside the JTS PCC working ceiling.
- **Why it matters:** Stretch vs Role 2 (~48 h) is about **1.5×**, not weeks. Antibiotic prophylaxis ≤72 h ends with the hold. The problem is not inventing a multi-week capsule; it is surviving three days without a second caregiver.
- **Source:** D1 phases P3; D2/D3 rescope; presentation Mission / Gap.
- **PoC implication:** Align clocks, prophylaxis cards, and bench scenarios to 72 h. Do not productise beyond exploratory prototypes.

### 1.2 Solo care gap

- **What:** Nearly every survival-improving prolonged-care intervention either needs a second person or becomes dangerous alone.
- **Why it matters:** Doctrine assumes a caregiver for critical acts. Self-applied tourniquet failure without outcome checks; only ~14% arrive Role II/III with prehospital care documented (D1). The gap is **solo**, not duration.
- **Source:** D1; KR-01–KR-08; Gap slide.
- **PoC implication:** Design for one-handed, degrading user; gate on outcomes; batch buddy tasks when contact occurs.

### 1.3 PoC, not productisation

- **What:** Exploratory build; distribution / App Store / MDR acceptance deferred.
- **Why it matters:** Market is saturated with AI health tools whose evidence base is thin; Finnish SOTE culture values **pilots and roadmaps before regulation**. Trustable clock/ledger before “smart” features.
- **Source:** KB — *There are more AI health tools than ever—but how well do they work?* (MIT TR, 2026-03-31); *Tech Exec’s Playbook for Clinical AI Implementation* (2026-04-08); *SOTE-tekoälykokeilujen tulokset…* (DigiFinland, 2026-04-14).
- **PoC implication:** Measure bench and UX learning goals. Do not claim clinical efficacy or ship readiness.

---

## 2. Life support

### 2.1 Fail-open ventilation

- **What:** Required ventilation **0.5–2 L/s** per casualty; **no closeable valve**; structurally impossible to seal; zero power.
- **Why it matters:** You cannot monitor your way out of a failure that incapacitates in ~30 minutes when the occupant is wounded and enclosed. Instrumentation is not a substitute for fail-open geometry.
- **Source:** D2 § Life support first.
- **PoC implication:** Bench the CO₂ path with and without occlusion attempts; prove vents cannot be closed.

### 2.2 CO₂ clock (~minutes sealed)

- **What:** Resting 80 kg adult ≈ **0.22 L/min CO₂** into ~150–400 L free air → occupational 0.5% ~7 min; 5% ~34 min; LOC ~10% / ~68 min.
- **Why it matters:** A sealed pod is a coffin on a ~one-hour timer. Nothing else in the casualty model kills this fast. Face at hooded aperture so exhaled CO₂ leaves without mixing; pod then needs only trickle vent.
- **Source:** D2 CO₂ arithmetic; presentation Life support.
- **PoC implication:** Never demo a sealed enclosure; recuperator + HME on vent path are part of the PoC hardware story.

### 2.3 Power must not be required to breathe

- **What:** Even with a large battery (powered tier), **ventilation remains fail-open / zero-power**.
- **Why it matters:** Battery death, BMS failure, or user error must not become asphyxia. Power enables compute, heat, cameras — never primary airflow.
- **Source:** D2 governing safety principle; powered-tier amendment.
- **PoC implication:** Hard acceptance test: kill power → airflow still present.

---

## 3. Thermal

### 3.1 Insulation, not chemical heat

- **What:** ~**70 W** metabolic heat; interior ~24 °C; at −10 °C need ~**53 mm** XLPE-eq. over body / **85 mm** beneath; Arctic −25 °C is a thickness decision (~80 / 128 mm).
- **Why it matters:** HPMK chemical heat is a **10-hour** answer to a **72-hour** problem (~7× short). Air-activated warmers add ~36% to O₂ demand. Combustion / catalytic heaters inside the volume are excluded (CO, no exit path).
- **Source:** D2 Thermal model; Three inversions.
- **PoC implication:** Bench insulation R-value / ΔT; do not plan chemical warmers as primary endurance.

### 3.2 Metabolic budget and vent heat penalty

- **What:** Naive 54 L/min vent at −10 °C costs ~**40 W** (over half metabolic budget). Counterflow recuperator (~70%) drops trickle penalty ~12.6 → ~3.8 W; HME recovers ~**11.5 W** and ~287 g water/day; respiration ≈ **24%** of heat budget.
- **Why it matters:** Ventilation and thermal are coupled. HME is best $/g thermal intervention and doubles as hydration when water is scarce.
- **Source:** D2.
- **PoC implication:** Include HME + recuperator in soft-pod BOM experiments.

### 3.3 When electrical heat becomes relevant

- **What:** Supplemental resistive heat below ~−10 °C or when metabolism collapses; stored energy **outside** occupied volume preferred.
- **Why it matters:** Passive retention stops closing the balance in deep cold or shock. Electrical heat is a powered-tier add-on, not the baseline product claim.
- **Source:** D2; powered BOM note.
- **PoC implication:** Size Wh only after heat + compute + charge budget is known; label costs TBD honestly.

---

## 4. Pressure / nursing

### 4.1 Interface pressures and myth of “32 mmHg safe”

- **What:** Bare litter: pelvis ~**42 mmHg**, heels ~**48 mmHg**. “32 mmHg is safe” is a documented myth.
- **Why it matters:** Pressure injury, not cold, dominates. Stage 3–4 forms well inside a week — still critical inside 72 h. Vacuum mattress is excellent insulator and among the worst multi-day support surfaces.
- **Source:** D2 Pressure & posture; D1.
- **PoC implication:** Zoned foam + sacral/heel relief; treat pressure as largest residual technical risk.

### 4.2 Tilt bladders and q1–2 h reposition

- **What:** Mouth-inflatable lateral tilt bladders (~USD 16, 300 g) so a lone casualty can offload one side; reposition remains **q1–2 h**.
- **Why it matters:** This is the nursing task doctrine gives to someone else. Bladders do not solve pressure injury; they return a lever to the casualty.
- **Source:** D2; KR-08.
- **PoC implication:** Usability test of self-tilt; app clock for reposition gates.

### 4.3 KR-08 — morale equals nursing

- **What:** Two-hourly turns, ankle pumps, oral care (~q12 h), daily log are one artefact.
- **Why it matters:** The nursing schedule **is** the morale architecture — body care preserves agency under prolonged hold.
- **Source:** D1 KR-08; psych amendment.
- **PoC implication:** One calm schedule UI, not separate “wellness” chrome.

---

## 5. Signature / dark UI

### 5.1 Screen visibility distances

- **What:** Screen light bracketed ~**0.5–2 km** ground / **1–6 km** airborne (vs cigarette / flashlight ranges).
- **Why it matters:** A bright phone can kill the user. Signature discipline is a **clinical subsystem** (KR-04), not a settings afterthought.
- **Source:** D1 emissions table; KR-04.
- **PoC implication:** Deep-red, minimum luminance, **screen-off as resting state** on field phone.

### 5.2 Lab PC may differ

- **What:** Gaming PC / lab MVP is allowed for psych + heavier local LLM; signature SOP applies to **field phone**, not lab PC.
- **Why it matters:** PoC learning speed vs field realism — share ledger schema across platforms.
- **Source:** Psych/Fitbit/PC amendment.
- **PoC implication:** Document which demos are lab-only.

### 5.3 Thermal signature of the pod

- **What:** Outer ΔT only ~**1.3–3.2 K** with good insulation; never metallise outward (cold anomaly).
- **Why it matters:** Same foam grams buy heat retention and concealment. Aluminised PET metal-face **inward** across an air gap.
- **Source:** D2 Signature / layer stack.
- **PoC implication:** Prototype imaging at ΔT 0.5–5 K is a cheap future bench; not required to start PoC UX.

---

## 6. Structural BOM (each major line)

Material costs are **indicative list**; no labour/tooling/margin. Soft subtotal **USD 552 / 15.37 kg**; protected **672+ / 47.27 kg**.

| Item | What | Why it matters | Source | PoC implication |
| --- | --- | --- | --- | --- |
| XLPE foam base 100 mm zoned | R≈2.7 + sacral/heel relief | Ground is the heat sink; base needs ~1.6× canopy R; zoning attacks highest pressure sites | D2 BOM / thermal / pressure | Cut sacral/heel relief; ASTM D3575 compression-set before foam lock |
| XLPE foam canopy 50 mm | R≈1.4 | Closes metabolic balance to ≈ −10 °C with base | D2 | Thickness trial vs ambient |
| TPU-coated nylon 6.6 ripstop | Shell, RF-weldable | Weather shell; ε match terrain; no red cross | D2 | Weld/zip prototype |
| Aluminised PET 12 µm | Radiant barrier, metal inward | Wrong orientation creates IR cold anomaly | D2 Signature | Orientation check in stack |
| Counterflow recuperator | ~70% recovery, no power | Makes trickle vent thermally affordable | D2 | Condensate/freeze drain design |
| HME respiratory ×3 | +11.5 W, water recovery | Best $/g thermal + hydration | D2 | Spare cartridges in kit |
| Mouth-inflatable tilt bladders ×2 | Self-offload | Solo nursing lever | D2 / KR-08 | Usability with one hand |
| Drag handles / hardware | One-person + UGV | Recovery without aeromedical | D2 | Load path with frame |
| Zips/closures FR | Full-length + limb ports | Access without defeating vent | D2 | Port leak/vent interaction |
| Graduated urine interface | Master field monitor | Urine volume is a self-measure that survives alone | D1 / D2 | Ledger units + clock |
| Vent screens fail-open ×2 | Cannot be closed | Primary life safety | D2 | Occlusion bench |
| Reflective sunshade detachable | Hot case | Overheat path without metallising shell outward | D2 | Optional |
| AutoLoader frame | Rails, pick points, CG | ~10 s load claim; mass budget reopened armour | D2 | Await CONTAI geometry |
| Fragment aramid ~3.9 m² | Detachable woven ~5.86 kg/m² | ~90% injuries fragmentation / FPV multi-hit | D2 Armour | Detachable layer; price TBD |

**Reject:** aerogel / VIP as primary insulation (cost/fragility; VIP fails silently if perforated).  
**Optional:** vacuum mattress; recommend alternating-pressure overlay+pump (~USD 400) for residual pressure risk.

---

## 7. Kit medicines & instruments

### 7.1 Cefadroxil conflict visibility

- **What:** Cefadroxil 1 g PO once daily × 3 (TCCC 01 May 2026). JTS ID 24 still names moxifloxacin — **surface both; do not silently pick**.
- **Why it matters:** Silent resolution of corpus conflict is a patient-safety defect (KR-09). Trust gap literature: visible doctrine conflicts build trust.
- **Source:** D3 / kit slide; KR-09; KB — *AI Trust Gap Slows Rev Cycle Transformation* (2026-03-18).
- **PoC implication:** Versioned attributed cards; UI shows conflict, does not auto-resolve.

### 7.2 Fixed doses only

- **What:** Pre-portioned daily analgesia pouches × 3; no weight-based arithmetic in app.
- **Why it matters:** Fixed doses beat calculation for a degrading user; calculation firewall is **safety architecture for PoC**, not store-compliance theatre. App Store 1.4.2 deferred post-PoC.
- **Source:** D3 §2.2 / §5.2 / §13.2 (historical gate); PoC rescope.
- **PoC implication:** Cards only; Swift never computes a dose.

### 7.3 Tourniquet outcome gate

- **What:** Gate on observable outcomes (e.g. distal pulse), not step confirmation.
- **Why it matters:** Measured failure mode is a confident user who skipped the check (KR-02 / FM-2).
- **Source:** D1; D3 C3.
- **PoC implication:** Protocol cards block on outcomes.

### 7.4 Thermometer, Fitbit, SpO₂

- **What:** External thermometer is a **kit line item** (iPhone has none). Fitbit / equiv BLE HR = default **trend** sensor; **SpO₂ never clinical**; signal loss is a finding.
- **Why it matters:** Consumer SpO₂ reads high, degrades in hypoxia/low perfusion/darker skin; App Review and D1 both exclude it from clinical logic. Self-measures remain load-bearing: pulse, urine, radial Y/N, cognitive vs baseline.
- **Source:** D1 sensors; D3; psych amendment.
- **PoC implication:** ≤60 s Fitbit sessions; provenance tags Wearable-derived vs Casualty-entered.

### 7.5 Other kit

- **What:** CAT ×≥1, haemostatic gauze, splint, spare HME, oral care (KR-08), handover print/QR path. Enoxaparin 30 mg BD only if haemostasis + >48 h expected (JTS ID 36). TXA etc. not listed as MedPod hold field-kit items in D1.
- **Why it matters:** Not a Role 2 pharmacy — hold kit for self-care + handover.
- **Source:** Kit slide / D1 delta.
- **PoC implication:** Keep kit page separate from structural BOM.

---

## 8. Powered tier

### 8.1 Large battery → PC, display, cameras, heat, charge

- **What:** Optional powered affordances on fail-open passive baseline: Li battery+BMS, gaming PC (lab), interior deep-red display, outward cameras, resistive pads, micro-pump, Fitbit path, USB charge. Costs **TBD** where unknown.
- **Why it matters:** Electricity can be available without rewriting life-safety. Changes mass, BOM, and emissions profile.
- **Source:** Powered BOM amendment; presentation.
- **PoC implication:** Lab smoke-test first; field SOP for cameras later.

### 8.2 Still fail-open vent

- **What:** Hard rule unchanged — power not required to breathe; no combustion/catalytic heater in occupied volume.
- **Why it matters:** See §2.3.
- **Source:** D2 / powered note.
- **PoC implication:** Same acceptance test under battery-present builds.

### 8.3 RPM analogy (careful)

- **What:** Bedside camera + display as RPM core in hospital programmes is analogous rationale for powered-tier outward/interior awareness **in lab/PoC**, with signature caveat in field.
- **Why it matters:** Continuous awareness helps when no medic is present — but field RF/optical emissions trade against survival (KR-04). Do not import hospital RPM assumptions wholesale.
- **Source:** KB — *RPM Is the Focus at UT Health San Antonio* (2026-02-18); D1 signature.
- **PoC implication:** Lab cameras OK; field default cameras off / SOP-gated.

---

## 9. App architecture

### 9.1 Clock + ledger before teacher (KR-01)

- **What:** C1 Clock (tourniquet 2 h/6 h, drugs, q1–2 h reposition, splint, dressing age) and C2 append-only ledger are irreplaceable; guidance is secondary.
- **Why it matters:** Memory fails over 72 h. Saturated AI-tool market and evidence gap argue: prove trustable state-keeping before generative “smart” features. Agents that follow up when clinicians cannot map to **prompts when no medic is present** — without claiming replacement of care.
- **Source:** D1 KR-01; D3 C1–C2; KB — *Tech Exec’s Playbook…* (2026-04-08); *MIT TR* evidence gap (2026-03-31); *AI agent that follows up when doctors can't* (Devpost, 2026-05-28).
- **PoC implication:** Ship clock+ledger UX first; defer free-form clinical chat.

### 9.2 Calculation firewall (Swift commits)

- **What:** All arithmetic and decision rules in deterministic Swift; model does **language only** (structure dictation, extract entities, summarise fixed protocols).
- **Why it matters:** On-device models are unreliable at math/reasoning; unsupervised clinical advice breaches safety posture. Patient-facing AI needs governance and personal context — local ledger + constrained prompts, not free-form medical chat.
- **Source:** D3 §5.2; KB — *Scaling patient-facing AI safely* (HealthLeaders, 2026-04-15); *AI Trust Gap…* (2026-03-18).
- **PoC implication:** Unit-test Swift core; model never computes dose/threshold.

### 9.3 Outcome gates; missed check = deterioration

- **What:** C3 outcome-gated cards; overdue checks are soft deterioration signal (C6 / psych §5).
- **Why it matters:** Confidence ≠ competence after training decay.
- **Source:** D1 FM-2 / KR-02; psych amendment.
- **PoC implication:** Missed-check framing in ledger and handover.

### 9.4 Handover / dead-man (C5)

- **What:** DD Form 1380 / MIST on demand and dead-man; readable without app or network (screen + QR).
- **Why it matters:** Strongest product argument; cheap; survives device handoff to a medic.
- **Source:** D3 C5 / R-11.
- **PoC implication:** Render packet early in PoC.

### 9.5 On-device speech; language proposes only

- **What:** SpeechAnalyzer / SpeechTranscriber path; VAD-gated; custom lexicon; no cloud ASR in ops. NFR-2: no network in operating state.
- **Why it matters:** Isolation premise shared with enclosure physics. Voice proposes; Swift commits.
- **Source:** D3 platform constraints.
- **PoC implication:** Build-time link check + runtime assertion; unsupervised clinical AI refused.

---

## 10. Psychological layer

### 10.1 KR-07 / KR-08

- **What:** Extraction is **recurring**, not terminal (failed attempt does not reset clock or shame). Nursing schedule is morale architecture.
- **Why it matters:** UGV retrieval often fails repeatedly; routine must survive failed rescues without collapsing hope or protocol.
- **Source:** D1 KR-07/08; psych amendment 2026-09-06.
- **PoC implication:** Extraction log + nursing-as-morale as first psych artefacts.

### 10.2 Cognitive vs personal baseline

- **What:** Timed micro-task; store latency/correctness **deltas only**; no diagnosis labels.
- **Why it matters:** Detect drift without pretending to diagnose cognitive impairment.
- **Source:** Psych amendment; D1 self-measures.
- **PoC implication:** Baseline in first mission window; Swift-only scoring.

### 10.3 Not therapy

- **What:** Fixed spoken strings; no open chat therapy; no suicide-risk scoring; no AI-companion romance; no crisis UI that claims to treat. Gap: no CPG for suicide/psych deterioration — **refuse to invent one**.
- **Why it matters:** Continuity architecture ≠ mental-health product. Inventing treatment UI without doctrine is unsafe.
- **Source:** Psych amendment §3 Hard rules.
- **PoC implication:** Six artefacts + hard refusals only.

---

## 11. AI / voice governance (PoC)

| What | Why it matters | Source | PoC implication |
| --- | --- | --- | --- |
| On-device only in ops | Zero network; signature + capture risk | D3 NFR-2 | Assert no calls |
| Language proposes; Swift commits | Unreliable model math; patient safety | D3 firewall; HealthLeaders 2026-04-15 | Firewall tests |
| No unsupervised clinical decisions | Named high-risk domain; human confirmation | D3 Gate 1 → PoC SAFE | Confirm every consequential action |
| Measure, don’t claim efficacy | Evidence gap in AI health tools | MIT TR 2026-03-31 | Bench + UX metrics |
| Governance before smart features | Market saturation; clinician/trust buy-in | Tech Exec Playbook 2026-04-08; Trust Gap 2026-03-18 | Clock/ledger first |
| Finnish pilot posture | Experimentation then regulation | DigiFinland SOTE 2026-04-14 | PoC framing fits |
| Follow-up when no medic | Maps to clock/prompts, not care replacement | Devpost agent 2026-05-28 | Prompt design careful |

**Deferred (post-PoC):** App Store Review 1.4.2 publisher path, EU MDR class, enterprise distribution. Fixed-dose + firewall remain regardless.


---

## Survivability claims discipline

### What we will say (PoC)

- **What:** Claims apply only to casualties who already cleared the acute filter (conscious; haemorrhage controlled enough to self-treat). Gain is framed as **avoided specific failure modes**, not a single battlefield survivability percentage.
- **Why it matters:** Doctrine under-serves *solo* post-acute killers: asphyxia-from-sealing, hypothermia from thin bags / ~10 h chemical heat, missed nursing clocks, self-aid TQ errors, missing handover (~14% documented). Pod + app can improve odds on those mechanisms if proxies are measured.
- **Source:** D1 Eastridge stack / self-TQ / handover; presentation Survivability claims; KR-07 extraction recurring.
- **PoC implication:** Measure proxies — hypothermia on recovery · Stage 2+ sores by 72 h · TQ verified occlusion · prophylaxis completed · handover completeness — then *model* a delta; never invent one.

### What we will not say

- **What:** No single survivability % for all battlefield wounded; no claim to fix truncal/junctional haemorrhage (~majority of potentially survivable bleeds); no claim to eliminate pressure injury (largest residual risk); no Role 2 / surgery replacement; no psych/suicide treatment (no CPG).
- **Why it matters:** Marketing-style “X% more survive with MedPod + app” would be dishonest. Evac-stretch arguments (~10%→~30% mortality) are about **time to surgery**, not this product. Evidence gap in AI health tools means PoC **measures**, does not claim clinical efficacy.
- **Source:** D1; KB — AI health tools under-evaluated (MIT TR 2026-03-31); psych amendment (no CPG).
- **PoC implication:** Slide and spec language stay scoped; Gates / Close keep “measure before claiming.”

### Evidence strip (D1 anchors)

| Figure | Meaning |
| --- | --- |
| ~2.6% of battlefield deaths | Extremity haemorrhage a lone casualty might self-treat (Eastridge stack) |
| ~63–65% | Lower-limb self-TQ success; common error = skip distal pulse |
| ~1 in 5 | UGV retrieval success; extraction is recurring |
| ~10%→~30% | Evac stretch mortality is time-to-surgery — out of product claim scope |

---

## Coupled thermal / CO₂ / signature design

### 1. CO₂ / ventilation

- **What:** Fail-open vents (no closeable valve); face at hooded aperture; trickle 0.5–2 L/s; counterflow recuperator (~70%); HME for respiratory heat/water. **Power must never be required to breathe** — powered tier still fail-open.
- **Why it matters:** Sealed ~150 L → ~34 min to 5% CO₂, ~1 h LOC; fastest killer. Instrumentation cannot substitute for fail-open geometry.
- **Source:** D2 life support; presentation Coupled constraints / Life support.
- **PoC implication:** Bench CO₂ path with occlusion attempts; kill-power acceptance test still shows airflow.

### 2. Heating need

- **What:** Insulation first — ~53 mm foam over / ~85 mm under closes balance on ~70 W metabolism to ≈ −10 °C with **0 W active heat**. Electrical heat only supplemental (powered tier) below ≈ −10 °C or collapsed metabolism; energy stored preferably outside occupied volume.
- **Why it matters:** HPMK chemical heat ~10 h vs 72 h (~7× short); air-activated warmers raise O₂ demand; combustion/catalytic inside the volume = CO with no exit.
- **Source:** D2 thermal; presentation Coupled constraints / Thermal & pressure.
- **PoC implication:** Prove passive balance on bench; treat active heat as last-resort option, never the product thesis.

### 3. Thermal signature (detection)

- **What:** Same insulation grams buy survival **and** smaller ΔT to ambient; radiant barrier **metal face inward** across air gap (never outward as camouflage); matte outer shell; no reflective sunshade as primary cold-signature strategy; screen-off / deep-red UI for phone emissions (KR-04).
- **Why it matters:** Hypothermia doctrine wants warmth; concealment hates a hot blob. Mylar-/aluminium-outward creates a **cold rectangle** on warm ground — often more conspicuous.
- **Source:** D2 signature notes; D1 KR-04; presentation Coupled constraints.
- **PoC implication:** Signature SOP for field phone; lab PC may differ; never demo metallised-out “camouflage.”

**Bottom line:** Insulation settles the heat–signature conflict; fail-open vent settles the seal–life conflict; active heat is last resort, never the product thesis.

---

## Cross-walk: presentation learning goals

1. Bench ventilation / thermal vs D2 numbers.  
2. Clock + ledger UX (phone and/or lab PC).  
3. Fitbit ≤60 s trend session.  
4. Psych continuity artefacts (KR-07/08) without therapy claims.  
5. Powered-tier smoke test with fail-open vent intact.  
6. Pressure residual (tilt + optional overlay); AutoLoader when data arrives.
7. Survivability claims discipline — measure proxies; refuse blanket %.
8. Coupled CO₂ / heat / signature design answers on one page.

---

*End of annotated spec · BattleMed (CONTAI) · Harri Juntunen · PoC · 6 Sep 2026 · 72 h*
