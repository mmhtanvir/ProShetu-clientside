import 'package:equatable/equatable.dart';

/// SOS categories. `inNeed` adds a "what are you looking for" field.
enum SosType { naturalDisaster, protestDistress, inNeed }

/// Draft of an SOS alert being composed.
class SosDraft extends Equatable {
  const SosDraft({
    required this.type,
    required this.name,
    required this.number,
    required this.location,
    this.lookingFor = '',
    this.description = '',
  });

  final SosType type;
  final String name;
  final String number;
  final String location;
  final String lookingFor;
  final String description;

  @override
  List<Object?> get props =>
      [type, name, number, location, lookingFor, description];
}
