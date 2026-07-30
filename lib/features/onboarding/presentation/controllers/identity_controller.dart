import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/identity_doc_type.dart';
import '../providers/onboarding_providers.dart';

class IdentityState extends Equatable {
  const IdentityState({
    this.docType,
    this.images = const [],
    this.submitting = false,
  });

  final IdentityDocType? docType;

  /// One slot per required photo (NID: [front, back]; BC: [document]).
  /// Null = not captured yet. Fixed length so users can replace any
  /// slot independently before submitting.
  final List<String?> images;

  final bool submitting;

  bool get isComplete =>
      docType != null &&
      images.length == docType!.requiredImages &&
      images.every((String? p) => p != null);

  IdentityState copyWith({
    IdentityDocType? docType,
    List<String?>? images,
    bool? submitting,
  }) =>
      IdentityState(
        docType: docType ?? this.docType,
        images: images ?? this.images,
        submitting: submitting ?? this.submitting,
      );

  @override
  List<Object?> get props => [docType, images, submitting];
}

/// Identity verification: document choice, per-slot captures, upload.
/// Kept alive (not autoDispose) so the congratulations screen can
/// still read which document type was submitted.
class IdentityController extends Notifier<IdentityState> {
  @override
  IdentityState build() => const IdentityState();

  void selectDocType(IdentityDocType type) {
    // Fresh, empty slots for the chosen document.
    state = IdentityState(
      docType: type,
      images: List<String?>.filled(type.requiredImages, null),
    );
  }

  /// Capture or replace the photo in a specific slot.
  void setImage(int slot, String path) {
    if (slot < 0 || slot >= state.images.length) return;
    final List<String?> next = [...state.images];
    next[slot] = path;
    state = state.copyWith(images: next);
  }

  /// Uploads once all slots are filled.
  Future<bool> submit() async {
    final IdentityDocType? type = state.docType;
    if (type == null || !state.isComplete) return false;
    state = state.copyWith(submitting: true);
    try {
      await ref.read(authRepositoryProvider).submitIdentity(
            docType: type,
            imagePaths: state.images.cast<String>(),
          );
      return true;
    } finally {
      state = state.copyWith(submitting: false);
    }
  }
}

final identityControllerProvider =
    NotifierProvider<IdentityController, IdentityState>(
  IdentityController.new,
);
