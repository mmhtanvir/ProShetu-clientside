# infrastructure/sync

Implementation lands with the first feature that needs it.
Rules: expose abstract interfaces consumed by features; features never
import platform/plugin code directly; heavy work stays off the UI isolate.
