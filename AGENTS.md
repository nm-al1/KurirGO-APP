# Repository Guidelines

## Project Structure & Module Organization

This repository contains **KurirGO (Browcyl Delivery)**, a Flutter mobile courier application with load verification (LIFO Stack), round-trip routing (Closed-Loop TSP), and multi-method cashier console for Browcyl in Makassar.

- `lib/core/`: Pure academic logic without external dependencies.
  - `algorithms/`: Held-Karp Bitmask DP, Nearest Neighbor, 2-Opt, Dijkstra router.
  - `dsa/`: `CargoStack` (LIFO), `AdjacencyMatrix` ($O(1)$ lookup), `MinHeap` Priority Queue, and `Graph`.
  - `theme/`: Design tokens, colors (`#18181B`, `#C6FF00`), and Inter typography scale.
- `lib/data/`: Domain data models (`OrderModel`, `WaypointModel`, `PaymentDetail`) and Makassar test fixtures (`dummy_makassar_data.dart`).
- `lib/features/`: UI presentation screens and controllers (`delivery_controller.dart`).
  - `auth/`: Login (`Frame_00_Login`) and Self-Registration (`Frame_00_Register`).
  - `dashboard/`: Shift overview & mini route stepper (`Frame_01_Dashboard`).
  - `load_verification/`: Physical trunk inspection (`Frame_02_VerifikasiMuatan`).
  - `route_preview/`: Geometric TSP graph preview (`Frame_03_RuteGraph_Preview`).
  - `live_navigation/`: Turn-by-turn navigation & cashier console (`Frame_04_LiveNavigation`).
- `bin/`: CLI benchmark tools (`bin/benchmark_tsp.dart`).
- `test/`: Unit tests for DSA (`test/dsa_test.dart`) and algorithms (`test/algorithms_test.dart`).
- `docs/`: Master documentation suite (`PRD.md`, `ARCHITECTURE.md`, `ALGORITHM_ANALYSIS.md`, `DSA_SPECIFICATION.md`).
- `design/`: SVG mockups and UI specification (`design.md`).

## Development & Validation Commands

Run these PowerShell commands from the repository root:

- `flutter analyze`: run Dart static analysis across the codebase.
- `flutter test`: execute all unit tests in `test/`.
- `dart run bin/benchmark_tsp.dart`: run the TSP Held-Karp vs Nearest Neighbor performance benchmark.
- `codegraph sync .`: sync symbol definitions with CodeGraph.
- `[xml](Get-Content -Raw -Encoding UTF8 design/Frame_01_Dashboard.svg) | Out-Null`: validate SVG mockup XML.

## Style & Naming Conventions

Use UTF-8 for Markdown and SVG files. Preserve Indonesian interface copy and existing screen terminology. Match the SVG convention of two-space indentation, quoted attributes, and descriptive group IDs.

Name screen assets `Frame_NN_ScreenName.svg`; retain the frame number and use `_ProMax` for the corresponding variant. Follow `design/design.md` for colors, typography, dimensions, and component names. Update the specification when intentionally changing those decisions.

## Testing Guidelines

No testing framework or coverage threshold is configured. Validate changed SVGs as XML, then inspect them visually at their declared dimensions. Check text clipping, alignment, route labels, and consistency across affected screens. XML parsing alone does not verify appearance. Refresh relevant previews when artwork changes.

## Commit & Pull Request Guidelines

This checkout has no Git metadata, so existing commit conventions cannot be verified. Use short, imperative messages such as `design: refine load verification states`.

For pull requests, describe affected frames and intended behavior, link an issue when available, and attach before/after screenshots for visual changes. State the validation performed and any remaining design questions.