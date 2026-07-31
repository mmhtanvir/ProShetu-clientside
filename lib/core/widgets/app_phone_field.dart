import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../infrastructure/location/location_providers.dart';

/// Phone number entry: a tappable country/dial-code picker (flag +
/// dial code) next to a plain digits field. The dial code preselects
/// from the device's current GPS fix (reverse-geocoded on-device,
/// see [currentCountryIsoProvider]) and falls back to the device's
/// locale region while that resolves or if location is unavailable —
/// the user can always tap the picker to override it.
///
/// Reports the combined E.164-shaped string (`dialCode + digits`, no
/// spaces) via [onChanged] on every edit, so callers can send it
/// straight to the backend without assembling it themselves.
class AppPhoneField extends ConsumerStatefulWidget {
  const AppPhoneField({
    required this.onChanged,
    this.label,
    this.errorText,
    this.hint,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  final ValueChanged<String> onChanged;
  final String? label;
  final String? errorText;
  final String? hint;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  ConsumerState<AppPhoneField> createState() => _AppPhoneFieldState();
}

class _AppPhoneFieldState extends ConsumerState<AppPhoneField> {
  final TextEditingController _digits = TextEditingController();
  String _dialCode = '+1';

  /// ISO seed for the picker. Set from GPS/locale until the user
  /// makes an explicit choice, then frozen to that choice — once
  /// frozen it must never be overwritten by a later GPS resolution,
  /// or the user's own pick would get silently reverted.
  String? _iso;
  bool _userPickedCountry = false;

  @override
  void dispose() {
    _digits.dispose();
    super.dispose();
  }

  void _emit() {
    final String digits = _digits.text.trim();
    widget.onChanged(digits.isEmpty ? '' : '$_dialCode$digits');
  }

  /// Device locale region (e.g. "BD", "US") — instant, offline, used
  /// only until the GPS-based lookup resolves (or if it never does).
  String? get _localeCountryFallback =>
      View.of(context).platformDispatcher.locale.countryCode;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<String?> gpsCountry =
        ref.watch(currentCountryIsoProvider);
    if (!_userPickedCountry) {
      _iso = gpsCountry.valueOrNull ?? _localeCountryFallback ?? _iso;
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    // country_code_picker hardcodes a white dialog/sheet fill and
    // unstyled text unless told otherwise — match the app's own
    // dialog/bottom-sheet surface (see AppTheme.dialogTheme) instead
    // of leaving it on the package's light-mode default.
    final TextStyle? listTextStyle =
        theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextField(
          controller: _digits,
          keyboardType: TextInputType.phone,
          textInputAction: widget.textInputAction,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _emit(),
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: CountryCodePicker(
                key: ValueKey(_iso),
                initialSelection: _iso,
                favorite: const ['+880', '+1'],
                padding: EdgeInsets.zero,
                flagWidth: 24,
                dialogBackgroundColor: AppColors.surfaceRaisedDark,
                backgroundColor: AppColors.surfaceRaisedDark,
                barrierColor: Colors.black.withValues(alpha: 0.5),
                textStyle: theme.textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurface),
                dialogTextStyle: listTextStyle,
                searchStyle: listTextStyle,
                searchDecoration: InputDecoration(
                  hintText: 'Search country',
                  hintStyle: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: scheme.outline),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: scheme.primary),
                  ),
                ),
                onInit: (CountryCode? code) {
                  if (code?.dialCode != null) {
                    _dialCode = code!.dialCode!;
                    _emit();
                  }
                },
                onChanged: (CountryCode code) {
                  setState(() {
                    _userPickedCountry = true;
                    _iso = code.code;
                    _dialCode = code.dialCode ?? _dialCode;
                  });
                  _emit();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
