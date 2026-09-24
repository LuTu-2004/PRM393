import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/text_utils.dart';

/// Saturation kept for absent students (spec: reduce by ~60%).
const double _absentSaturation = 0.4;

ColorFilter _saturation(double s) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final i = 1 - s;
  return ColorFilter.matrix([
    r * i + s, g * i, b * i, 0, 0, //
    r * i, g * i + s, b * i, 0, 0, //
    r * i, g * i, b * i + s, 0, 0, //
    0, 0, 0, 1, 0,
  ]);
}

/// Resolves a stored image path to an [ImageProvider], or null.
ImageProvider? photoProviderFor(String? path) =>
    path == null || path.isEmpty ? null : FileImage(File(path));

/// A student's ID photo, or initials on a light-ink tile when missing.
///
/// Fills the space given by the parent; callers decide the aspect ratio.
class StudentPhoto extends StatelessWidget {
  const StudentPhoto({
    super.key,
    required this.fullName,
    this.photo,
    this.desaturate = false,
    this.radius = Radii.photo,
    this.initialsSize,
  });

  final String fullName;
  final ImageProvider? photo;

  /// Grays the photo out for absent students.
  final bool desaturate;
  final double radius;

  /// Font size of the initials; scales with the box when null.
  final double? initialsSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget child = LayoutBuilder(
      builder: (context, box) {
        final fallback = Container(
          color: c.inkSoft,
          alignment: Alignment.center,
          child: Text(
            initialsOf(fullName),
            style: context.text.bodyStrong.copyWith(
              color: c.ink,
              fontWeight: FontWeight.w700,
              fontSize: initialsSize ?? (box.maxWidth * 0.3).clamp(12, 96),
              height: 1,
            ),
          ),
        );
        if (photo == null) return fallback;
        return Image(
          image: photo!,
          fit: BoxFit.cover,
          width: box.maxWidth,
          height: box.maxHeight,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => fallback,
        );
      },
    );
    if (desaturate) {
      child = ColorFiltered(
        colorFilter: _saturation(_absentSaturation),
        child: child,
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}
