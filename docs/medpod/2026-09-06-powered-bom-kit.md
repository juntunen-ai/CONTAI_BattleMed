# Design amendment — MedPod BOM, 72 h kit, powered tier (PoC)

**Programme:** BattleMed (CONTAI) · MedPod + app · **PoC**  
**Author context:** Harri Juntunen / BattleMed (CONTAI)  
**Date:** 6 September 2026 (EEST)  
**Hold:** 72 hours  
**Status:** Proof of Concept (PoC) — exploratory; App Store / MDR / distribution deferred.

## What changed

Three slides after **07 · MedPod · Envelope** and before App MVP:

1. **08 · MedPod · BOM** — soft-pod + protected structural materials (indicative list prices; no labour/tooling/margin). Soft subtotal **USD 552 / 15.37 kg**; protected **USD 672+ / 47.27 kg**. Optional: vacuum mattress; recommend alternating-pressure overlay+pump. Reject aerogel / VIP.
2. **09 · MedPod · Kit** — medicines & instruments for 72 h hold, **separate** from structural BOM. Fixed-dose only; cite TCCC / JTS; surface conflicts (e.g. cefadroxil vs JTS ID 24 moxifloxacin). Not a Role 2 pharmacy; no dose calc in app — **safety architecture for PoC**, not store-compliance theatre.
3. **10 · MedPod · Powered tier** — large battery allowed as a programme decision on top of fail-open passive baseline. Hard rules: ventilation zero-power primary; no combustion/catalytic heater in occupied volume; electrical heat supplemental only. Affordances listed with **TBD** costs where unknown.

Kickers and footer `pg` markers: **18 pages** total. Footers: **BattleMed (CONTAI) · PoC · 72 h · 6 Sep 2026**.

## Light touch-ups (PoC rescope)

- Envelope totals aligned to soft **552** / protected **672+** / **47.3 kg**; powered tier exists.
- Programme-map D2 blurb updated.
- Gates: PoC learning goals (bench, clock+ledger, Fitbit, psych) — App Store 1.4.2 demoted to **Deferred (post-PoC)**.
- Close: PoC briefing / prototype experiments (not publisher blockers).

## Artefacts

- `docs/medpod/presentation.html`
- `docs/medpod/CONTAI_BattleMed_MedPod_Presentation_72h.pdf`
- `docs/medpod/CONTAI_BattleMed_MedPod_Presentation_72h.pdf` (72 h PoC)
- `docs/medpod/PoC_Annotated_Spec.md`

Indexed in this repo under `docs/medpod/` as `2026-09-06-powered-bom-kit.md` and the 72 h presentation PDF.

## Finnish 4-bullet (user)

- PoC-kehys: App Store / MDR myöhemmin.
- Kolme diaa: BOM, lääke-/instrumenttikitti (72 h), powered-tier.
- Soft-pod ~552 USD / suojattu 672+; tuuletus fail-open / nollateho.
- PDF 18 sivua A4 landscape → Downloads.
