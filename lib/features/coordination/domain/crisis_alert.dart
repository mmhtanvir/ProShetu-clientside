import 'package:equatable/equatable.dart';

/// A community crisis alert shown on the dashboard.
class CrisisAlert extends Equatable {
  const CrisisAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.ageLabel,
  });

  final String id;
  final String title;
  final String body;
  final String ageLabel;

  @override
  List<Object?> get props => [id, title, body, ageLabel];
}
