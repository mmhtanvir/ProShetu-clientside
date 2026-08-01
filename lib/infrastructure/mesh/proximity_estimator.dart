import 'ble_mesh_types.dart';

/// Turns raw, noisy RSSI samples into a stable [ProximityBucket] per
/// device. Pure logic, no plugin/platform dependency — unit-testable
/// on its own.
///
/// Two smoothing steps, both necessary: an exponential moving average
/// (EMA) irons out sample-to-sample RSSI jitter (a single reading can
/// swing 10+ dBm between two consecutive scans of the same stationary
/// device), and hysteresis on top of that stops a value sitting right
/// on a bucket boundary from flapping the UI between "very close" and
/// "nearby" every tick.
class ProximityEstimator {
  ProximityEstimator({
    this.emaAlpha = 0.3,
    this.hysteresisDb = 4,
    this.veryCloseThresholdDb = -60,
    this.nearbyThresholdDb = -80,
  });

  /// Weight given to each new sample; higher reacts faster but is
  /// noisier, lower is smoother but laggier.
  final double emaAlpha;

  /// How far a reading must cross a bucket boundary, beyond the
  /// boundary itself, before the bucket actually changes.
  final double hysteresisDb;

  final double veryCloseThresholdDb;
  final double nearbyThresholdDb;

  final Map<String, double> _smoothed = {};
  final Map<String, ProximityBucket> _buckets = {};

  /// Feeds one new raw RSSI sample for [deviceId] and returns the
  /// (possibly unchanged) smoothed RSSI + bucket for it.
  (double smoothedRssi, ProximityBucket bucket) sample(
    String deviceId,
    int rawRssi,
  ) {
    final double previous = _smoothed[deviceId] ?? rawRssi.toDouble();
    final double next = previous + emaAlpha * (rawRssi - previous);
    _smoothed[deviceId] = next;

    final ProximityBucket current = _buckets[deviceId] ?? _bucketFor(next);
    final ProximityBucket resolved = _applyHysteresis(current, next);
    _buckets[deviceId] = resolved;

    return (next, resolved);
  }

  void forget(String deviceId) {
    _smoothed.remove(deviceId);
    _buckets.remove(deviceId);
  }

  ProximityBucket _bucketFor(double rssi) {
    if (rssi >= veryCloseThresholdDb) return ProximityBucket.veryClose;
    if (rssi >= nearbyThresholdDb) return ProximityBucket.nearby;
    return ProximityBucket.far;
  }

  ProximityBucket _applyHysteresis(ProximityBucket current, double rssi) {
    switch (current) {
      case ProximityBucket.veryClose:
        return rssi < veryCloseThresholdDb - hysteresisDb
            ? _bucketFor(rssi)
            : ProximityBucket.veryClose;
      case ProximityBucket.nearby:
        if (rssi >= veryCloseThresholdDb + hysteresisDb) {
          return ProximityBucket.veryClose;
        }
        if (rssi < nearbyThresholdDb - hysteresisDb) {
          return ProximityBucket.far;
        }
        return ProximityBucket.nearby;
      case ProximityBucket.far:
        return rssi >= nearbyThresholdDb + hysteresisDb
            ? _bucketFor(rssi)
            : ProximityBucket.far;
    }
  }
}
