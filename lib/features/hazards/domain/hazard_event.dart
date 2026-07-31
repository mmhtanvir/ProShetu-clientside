import 'package:equatable/equatable.dart';

enum HazardType { earthquake, flood }

/// A single external hazard alert — from USGS (earthquakes) or
/// Google's Flood Forecasting API (floods). Distinct from
/// [MapMarker]/[CoordDelta] (coordination/domain): those are
/// user-reported, encrypted, geohash-sharded SOS pins from our own
/// backend. These are public, unencrypted, third-party data with no
/// relation to this app's identity/crypto layer at all.
class HazardEvent extends Equatable {
  const HazardEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.time,
    required this.severityLabel,
    this.magnitude,
    this.detailUrl,
  });

  final String id;
  final HazardType type;
  final String title;
  final double latitude;
  final double longitude;
  final DateTime time;

  /// Plain-language severity, already resolved from whatever
  /// source-specific enum/magnitude scale produced it — never a raw
  /// enum surfaced to the UI unchanged (both sources' severity scales
  /// can gain new values without warning; see the clients' doc
  /// comments for why this is deliberately a free-text fallback).
  final String severityLabel;

  /// Earthquakes only.
  final double? magnitude;

  final String? detailUrl;

  @override
  List<Object?> get props => [id, type, title, latitude, longitude, time];
}
