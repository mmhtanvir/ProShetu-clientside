import 'package:equatable/equatable.dart';

import '../../panic/domain/sos_alert.dart';

/// A published SOS alert plotted on the crisis map.
///
/// This is the "read" counterpart of [SosDraft] (panic feature): once
/// an SOS alert is broadcast, it becomes a pin other mesh peers can
/// see, tap, and read — reusing the same [SosType] categories so the
/// compose flow and the map stay in sync.
class MapMarker extends Equatable {
  const MapMarker({
    required this.id,
    required this.type,
    required this.reporterName,
    required this.number,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.ageLabel,
    this.lookingFor = '',
    this.description = '',
  });

  final String id;
  final SosType type;

  /// Who filed the report ("Created By" on the detail sheet).
  final String reporterName;
  final String number;
  final String location;
  final double latitude;
  final double longitude;

  /// Pre-formatted relative time, e.g. "16 hr ago" — matches the
  /// [CrisisAlert.ageLabel] convention used on the dashboard.
  final String ageLabel;

  /// Only meaningful for [SosType.inNeed].
  final String lookingFor;
  final String description;

  @override
  List<Object?> get props => [
        id,
        type,
        reporterName,
        number,
        location,
        latitude,
        longitude,
        ageLabel,
        lookingFor,
        description,
      ];
}
