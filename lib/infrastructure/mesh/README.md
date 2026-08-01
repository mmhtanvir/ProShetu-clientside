# infrastructure/mesh

Real BLE proximity discovery — Phase 1 only. Rules: expose abstract
interfaces consumed by features; features never import platform/plugin
code directly; heavy work stays off the UI isolate.

## Scope: Phase 1, discovery only, no message relay

This is honest device discovery + signal-strength-based proximity
bucketing. It is **not** a mesh transport — no message relay over
Bluetooth. That's independently multi-month/research-grade scope
(duty-cycled scan/advertise, multi-peer connection management,
resumable transfers, iOS's severe background-BLE restrictions) and was
explicitly descoped. If real relay is ever wanted, evaluate a
commercial SDK (e.g. Bridgefy) as a buy-vs-build decision before
attempting it from scratch.

Foreground-only: scanning/advertising starts when the mesh screen
opens and stops on dispose. No background modes requested.

## Why peers are anonymous in Phase 1

The original design for this phase called for an authenticated
nonce/signature identity handshake over a GATT connection, once a
scanner found a device. That turned out not to be buildable with the
plugins in use, for a concrete, verified reason, not a guess:

- `flutter_ble_peripheral` (the peripheral/advertising role) exposes
  **no API for defining a custom GATT service or characteristic** —
  its entire public surface is `start(AdvertiseData)`/`stop()`/status
  getters. There is nothing to attach an identity characteristic to.
- Even limited to advertisement payloads instead of a GATT exchange,
  the plugin's own README states iOS supports **only** "Advertise
  UUID" — manufacturer data and custom service data are Android-only.
  So there's no cross-platform advertisement field to carry a rotating
  identity token either.

Building a custom native plugin with a real GATT server was judged
out of proportion for a "Phase 1, discovery-only" scope — that's
exactly the kind of from-scratch platform-channel work Phase 2 (relay)
was already descoped for.

**Consequence**: `DiscoveredMeshPeer.mailboxId`/`.displayName` are
always `null` today. The UI shows nearby devices as anonymous
("Unknown nearby device"), not linked to any contact, with the chat
action disabled until a future phase can actually resolve identity
(e.g. a GATT server via a purpose-built native plugin, or a
short-range QR/NFC handshake instead of BLE for the identity step).
This was accounted for in the domain model from the start, not bolted
on after the fact.

## What's here

- `ble_mesh_types.dart` — shared constants (`kMeshServiceUuid`) and
  types (`ProximityBucket`, `MeshAvailability`, `DiscoveredMeshPeer`).
- `proximity_estimator.dart` — pure RSSI smoothing (EMA) + hysteresis
  bucketing. No plugin dependency, unit-testable standalone.
- `ble_central_scanner.dart` — thin wrapper over `flutter_blue_plus`'s
  scanning (central) role, filtered to `kMeshServiceUuid`.
- `ble_peripheral_advertiser.dart` — thin wrapper over
  `flutter_ble_peripheral`'s advertising (peripheral) role.
- `ble_mesh_repository.dart` — combines both roles, permission
  requests (Android's split `BLUETOOTH_SCAN`/`ADVERTISE`/`CONNECT`),
  Bluetooth-adapter-state/support checks, and stale-peer pruning into
  one `Stream<List<DiscoveredMeshPeer>>` + `Stream<MeshAvailability>`.
  This is the only file in this directory that imports either plugin.
