import 'package:flutter/material.dart';

import 'notebook_colors.dart';
import 'notebook_text.dart';

export 'notebook_colors.dart';
export 'notebook_text.dart';

/// Corner radii: deliberately graded, never "round everything the same".
abstract final class Radii {
  static const double photo = 6;
  static const double card = 10;
  static const double button = 10;
  static const double input = 10;
  static const double dialog = 16;
}

/// Spacing scale (4pt based).
abstract final class Gaps {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Motion durations. All motion is disabled when the OS asks to reduce it.
abstract final class Motion {
  static const stamp = Duration(milliseconds: 160);
  static const selection = Duration(milliseconds: 120);
  static const counter = Duration(milliseconds: 200);
  static const listInsert = Duration(milliseconds: 180);

  /// Returns [d], or zero when the platform requests reduced motion.
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;
}

/// Size of one cell of the ruled "ô ly" grid.
const double kGridCell = 24;

extension NotebookThemeX on BuildContext {
  NotebookColors get colors => Theme.of(this).extension<NotebookColors>()!;
  NotebookText get text => Theme.of(this).extension<NotebookText>()!;
}

abstract final class AppTheme {
  static ThemeData light() => _build(NotebookColors.light, Brightness.light);
  static ThemeData dark() => _build(NotebookColors.dark, Brightness.dark);

  static ThemeData _build(NotebookColors c, Brightness brightness) {
    final t = NotebookText.from(c);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.ink,
      onPrimary: c.onInk,
      primaryContainer: c.inkSoft,
      onPrimaryContainer: c.text,
      secondary: c.ink,
      onSecondary: c.onInk,
      error: c.redPen,
      onError: c.onInk,
      errorContainer: c.redPenSoft,
      onErrorContainer: c.text,
      surface: c.paper,
      onSurface: c.text,
      onSurfaceVariant: c.pencilText,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surface,
      surfaceContainerHighest: c.surface,
      outline: c.gridLine,
      outlineVariant: c.gridLine,
      shadow: Colors.transparent,
      scrim: c.text.withValues(alpha: 0.32),
      surfaceTint: Colors.transparent,
      inverseSurface: c.text,
      onInverseSurface: c.paper,
    );

    final textTheme = TextTheme(
      displayLarge: t.hugeNumber,
      displayMedium: t.bigNumber,
      headlineSmall: t.screenTitle,
      titleLarge: t.screenTitle,
      titleMedium: t.sectionTitle,
      titleSmall: t.bodyStrong,
      bodyLarge: t.body,
      bodyMedium: t.body,
      bodySmall: t.caption,
      labelLarge: t.body.copyWith(fontWeight: FontWeight.w600, height: 1.2),
      labelMedium: t.caption.copyWith(color: c.text, height: 1.2),
      labelSmall: t.caption.copyWith(fontSize: 12, height: 1.2),
    );

    final hover = c.ink.withValues(alpha: 0.06);
    final pressed = c.ink.withValues(alpha: 0.12);
    final focusRing = BorderSide(color: c.ink, width: 2);

    WidgetStateProperty<Color?> overlay() => WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.pressed)
          ? pressed
          : s.contains(WidgetState.hovered)
          ? hover
          : null,
    );

    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(Radii.button)),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);
    const buttonMinSize = Size(40, 44);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: kFontFamily,
      textTheme: textTheme,
      extensions: [c, t],
      scaffoldBackgroundColor: c.paper,
      canvasColor: c.paper,
      dividerColor: c.gridLine,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: hover,
      focusColor: c.ink.withValues(alpha: 0.10),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      dividerTheme: DividerThemeData(color: c.gridLine, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.text, size: 20),
      appBarTheme: AppBarTheme(
        backgroundColor: c.paper,
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: t.screenTitle,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.gridLine : c.ink,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.pencilText : c.onInk,
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.pressed)
                ? c.onInk.withValues(alpha: 0.16)
                : s.contains(WidgetState.hovered)
                ? c.onInk.withValues(alpha: 0.08)
                : null,
          ),
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused)
                ? BorderSide(color: c.text, width: 2)
                : BorderSide.none,
          ),
          elevation: const WidgetStatePropertyAll(0),
          shape: const WidgetStatePropertyAll(buttonShape),
          padding: const WidgetStatePropertyAll(buttonPadding),
          minimumSize: const WidgetStatePropertyAll(buttonMinSize),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.pencilText : c.text,
          ),
          backgroundColor: WidgetStatePropertyAll(c.surface),
          overlayColor: overlay(),
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused)
                ? focusRing
                : BorderSide(color: c.gridLine),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shape: const WidgetStatePropertyAll(buttonShape),
          padding: const WidgetStatePropertyAll(buttonPadding),
          minimumSize: const WidgetStatePropertyAll(buttonMinSize),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.pencilText : c.ink,
          ),
          overlayColor: overlay(),
          side: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.focused) ? focusRing : BorderSide.none,
          ),
          shape: const WidgetStatePropertyAll(buttonShape),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          minimumSize: const WidgetStatePropertyAll(buttonMinSize),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.pencil : c.text,
          ),
          overlayColor: overlay(),
          side: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.focused) ? focusRing : BorderSide.none,
          ),
          shape: const WidgetStatePropertyAll(buttonShape),
          minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.inkSoft : c.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.ink : c.text,
          ),
          overlayColor: overlay(),
          side: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.focused)
                ? focusRing
                : BorderSide(color: c.gridLine),
          ),
          shape: const WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.inkSoft,
        disabledColor: c.gridLine,
        side: BorderSide(color: c.gridLine),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium,
        checkmarkColor: c.ink,
        elevation: 0,
        pressElevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        hintStyle: t.body.copyWith(color: c.pencilText),
        labelStyle: t.body.copyWith(color: c.pencilText),
        floatingLabelStyle: t.caption.copyWith(color: c.ink),
        prefixIconColor: c.pencilText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide(color: c.gridLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide(color: c.gridLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide(color: c.ink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide(color: c.redPen),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide(color: c.redPen, width: 2),
        ),
        errorStyle: t.caption.copyWith(color: c.redPen),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(color: c.gridLine),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.dialog),
          side: BorderSide(color: c.gridLine),
        ),
        titleTextStyle: t.sectionTitle,
        contentTextStyle: t.body,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(color: c.gridLine),
        ),
        textStyle: t.body,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surface),
          elevation: const WidgetStatePropertyAll(0),
          side: WidgetStatePropertyAll(BorderSide(color: c.gridLine)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.card),
            ),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: t.body,
        // Same height as text fields (~44px) instead of Material's 56px.
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: c.surface,
          isDense: true,
          constraints: const BoxConstraints(maxHeight: 44),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.input),
            borderSide: BorderSide(color: c.gridLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.input),
            borderSide: BorderSide(color: c.ink, width: 2),
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surface),
          elevation: const WidgetStatePropertyAll(0),
          side: WidgetStatePropertyAll(BorderSide(color: c.gridLine)),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        indicatorColor: c.inkSoft,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.button)),
        ),
        selectedIconTheme: IconThemeData(color: c.ink, size: 20),
        unselectedIconTheme: IconThemeData(color: c.pencilText, size: 20),
        selectedLabelTextStyle: t.body.copyWith(
          color: c.ink,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: t.body.copyWith(color: c.text),
        minWidth: 72,
        minExtendedWidth: 220,
        useIndicator: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.text,
        contentTextStyle: t.body.copyWith(color: c.paper),
        actionTextColor: c.highlighter,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        width: 480,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: c.redPenSoft,
        contentTextStyle: t.body,
        elevation: 0,
        dividerColor: c.gridLine,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.text,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: t.caption.copyWith(color: c.paper),
        waitDuration: const Duration(milliseconds: 400),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(c.pencil.withValues(alpha: 0.5)),
        radius: const Radius.circular(4),
        thickness: const WidgetStatePropertyAll(6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.ink,
        linearTrackColor: c.gridLine,
        circularTrackColor: Colors.transparent,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.ink : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(c.onInk),
        side: BorderSide(color: c.pencil, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.ink : c.pencil,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onInk : c.pencil,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.ink : c.surface,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.ink : c.gridLine,
        ),
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: t.body,
        subtitleTextStyle: t.caption,
        iconColor: c.pencilText,
        selectedColor: c.ink,
        selectedTileColor: c.inkSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.button),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: t.caption.copyWith(fontWeight: FontWeight.w600),
        dataTextStyle: t.body,
        dividerThickness: 1,
        headingRowHeight: 44,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.ink,
        selectionColor: c.ink.withValues(alpha: 0.25),
        selectionHandleColor: c.ink,
      ),
    );
  }
}
