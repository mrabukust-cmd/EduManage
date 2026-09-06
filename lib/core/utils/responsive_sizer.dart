import 'package:flutter/material.dart';

/// Screen type categorization based on standard breakpoint guidelines.
enum ScreenType {
  mobile,
  tablet,
  desktop,
  watch,
}

/// Device dimension and orientation state store.
/// Populated by [ResponsiveSizer] at application root or screen level.
class Device {
  Device._();

  static double width = 375;
  static double height = 812;
  static double aspectRatio = 0.5;
  static double pixelRatio = 1.0;
  static Orientation orientation = Orientation.portrait;
  static ScreenType screenType = ScreenType.mobile;
  static BoxConstraints boxConstraints = const BoxConstraints();

  /// Updates device metrics from current constraints and media query.
  static void setScreenSize(
    BoxConstraints constraints,
    Orientation currentOrientation,
    MediaQueryData mediaQuery,
  ) {
    boxConstraints = constraints;
    orientation = currentOrientation;
    pixelRatio = mediaQuery.devicePixelRatio;

    // Use box constraints if bounded, otherwise fallback to mediaQuery size
    if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
      width = constraints.maxWidth;
    } else {
      width = mediaQuery.size.width;
    }

    if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
      height = constraints.maxHeight;
    } else {
      height = mediaQuery.size.height;
    }

    aspectRatio = width > 0 && height > 0 ? width / height : 0.5;

    // Determine device category
    final shortestSide = width < height ? width : height;
    if (shortestSide < 300) {
      screenType = ScreenType.watch;
    } else if (shortestSide < 600) {
      screenType = ScreenType.mobile;
    } else if (shortestSide < 1024) {
      screenType = ScreenType.tablet;
    } else {
      screenType = ScreenType.desktop;
    }
  }
}

/// Adaptive scaling calculation utilities.
class Adaptive {
  Adaptive._();

  /// Height percentage calculation: [percent]% of screen height.
  static double h(num percent) => (percent * Device.height) / 100;

  /// Width percentage calculation: [percent]% of screen width.
  static double w(num percent) => (percent * Device.width) / 100;

  /// Scalable text size based on reference mobile viewport (375pt).
  /// Clamped between 0.85x and 1.35x to avoid exaggerated fonts on tablets.
  static double sp(num size) {
    final scale = (Device.width / 375).clamp(0.85, 1.35);
    return (size * scale).toDouble();
  }

  /// Adaptive dimension / radius relative to screen width.
  static double dp(num value) {
    final scale = (Device.width / 375).clamp(0.85, 1.30);
    return (value * scale).toDouble();
  }
}

/// Extension on [num] to write responsive dimensions declaratively.
///
/// Example:
/// ```dart
/// Container(
///   width: 50.w, // 50% screen width
///   height: 20.h, // 20% screen height
///   child: Text('Hello', style: TextStyle(fontSize: 16.sp)),
/// );
/// ```
extension ResponsiveSizerNumExtension on num {
  /// Height percentage (0 - 100). E.g. `20.h` is 20% of device height.
  double get h => Adaptive.h(this);

  /// Width percentage (0 - 100). E.g. `50.w` is 50% of device width.
  double get w => Adaptive.w(this);

  /// Scalable font size in sp. E.g. `14.sp`.
  double get sp => Adaptive.sp(this);

  /// Scalable radius / padding in dp. E.g. `12.r`.
  double get r => Adaptive.dp(this);

  /// Creates a vertical [SizedBox] using screen height percentage.
  /// E.g. `2.h.hSpace` or `2.5.hSpace` (where 2.5 means 2.5% of height).
  Widget get hSpace => SizedBox(height: (this * Device.height) / 100);

  /// Creates a horizontal [SizedBox] using screen width percentage.
  /// E.g. `4.wSpace` (where 4 means 4% of width).
  Widget get wSpace => SizedBox(width: (this * Device.width) / 100);

  /// Fixed height space. E.g. `16.verticalSpace`.
  Widget get verticalSpace => SizedBox(height: toDouble());

  /// Fixed width space. E.g. `16.horizontalSpace`.
  Widget get horizontalSpace => SizedBox(width: toDouble());
}

/// Extension on [BuildContext] for responsive layout helpers.
extension ResponsiveContextExtension on BuildContext {
  /// Current screen height from device metrics.
  double get screenHeight => Device.height;

  /// Current screen width from device metrics.
  double get screenWidth => Device.width;

  /// Current screen orientation.
  Orientation get orientation => Device.orientation;

  /// Current screen type (mobile, tablet, desktop).
  ScreenType get screenType => Device.screenType;

  /// True when the device is categorized as a mobile phone.
  bool get isMobile => Device.screenType == ScreenType.mobile;

  /// True when the device is categorized as a tablet.
  bool get isTablet => Device.screenType == ScreenType.tablet;

  /// True when the device is categorized as a desktop or wide web screen.
  bool get isDesktop => Device.screenType == ScreenType.desktop;

  /// True when the device is in portrait mode.
  bool get isPortrait => Device.orientation == Orientation.portrait;

  /// True when the device is in landscape mode.
  bool get isLandscape => Device.orientation == Orientation.landscape;

  /// Return value matching current screen type.
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}

/// Signature for responsive sizer builder function.
typedef ResponsiveBuild = Widget Function(
  BuildContext context,
  Orientation orientation,
  ScreenType screenType,
);

/// Root or local widget that initializes and updates [Device] metrics.
class ResponsiveSizer extends StatelessWidget {
  final ResponsiveBuild builder;

  const ResponsiveSizer({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            MediaQueryData mediaQuery;
            try {
              mediaQuery = MediaQuery.of(context);
            } catch (_) {
              mediaQuery = MediaQueryData.fromView(View.of(context));
            }

            Device.setScreenSize(constraints, orientation, mediaQuery);
            return builder(context, orientation, Device.screenType);
          },
        );
      },
    );
  }
}

/// Conditional layout builder for Mobile, Tablet, and Desktop representations.
class ResponsiveLayout extends StatelessWidget {
  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop && desktop != null) {
      return desktop!(context);
    }
    if (context.isTablet && tablet != null) {
      return tablet!(context);
    }
    return mobile(context);
  }
}
