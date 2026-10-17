# PricePulse · UI/UX Design Specification

Design direction and implementation-ready specs for the Flutter + Firebase prototype.

## Documents

| File | Content | Deliverables covered |
|---|---|---|
| [01_rationale_and_ia.md](01_rationale_and_ia.md) | Product experience, personas, design priorities, principles, assumptions, IA, navigation map, user journeys | ☑ 1 design rationale · ☑ 2 IA & nav map · ☑ 3 user flows |
| [02_design_system.md](02_design_system.md) | Color/typography/spacing/radius tokens, motion, accessibility baseline, full reusable component inventory | ☑ 4 design system & components |
| [03a_home_and_comparison.md](03a_home_and_comparison.md) | Home / Discover and Product Details / Price Comparison — the hero screens, layed out and specified for Flutter | ☑ 5 screen-by-screen · ☑ 6 layout & interaction |
| [03b_remaining_screens.md](03b_remaining_screens.md) | Search Results, Favorites, Authentication (welcome/login/register/forgot), Account/Settings, supporting flows | ☑ 5 · ☑ 6 |
| [04_states_qa_handoff.md](04_states_qa_handoff.md) | Global state catalog, 50-product sample dataset (clearly marked seed data), design QA checklist, file map + build order + open questions | ☑ 7 sample content · ☑ 8 states · ☑ 9 QA · ☑ 10 handoff |

## Status

Design: **complete (v1.0)** — Milestone 2 implementation **done** (Flutter
foundation, design tokens, component library, Home + Product Details +
lean Search Results). See the project `README.md` and `lib/` for the code.

Key scope guardrails encoded in the design and now in code: recorded (not
live) prices with freshness labels, no social login, no fake marketplace
links, savings only across comparable offers, and every loading/empty/error
state designed explicitly.