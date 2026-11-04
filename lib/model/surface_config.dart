import 'color_ref.dart';
import 'shadow_token.dart';
import 'typography_config.dart';

/// Properties a container can expose in the editor.
enum SurfaceProp {
  background,
  foreground,
  borderColor,
  borderWidth,
  radius,
  elevation,
  accent,
  titleStyle,
  bodyStyle,
  height,
  shadow,
  paddingH,
  paddingV,
  innerRadius,
  selectedForeground,
  accentEnd,
  shadowColor,
  width,
  thumbSize,
  trackBorderWidth,
}

/// I contenitori Material configurabili.
enum SurfaceKind {
  card('Card', 'CardThemeData', {
    SurfaceProp.background: 'Background',
    SurfaceProp.borderColor: 'Border',
    SurfaceProp.borderWidth: 'Border width',
    SurfaceProp.radius: 'Radius',
    SurfaceProp.elevation: 'Elevation',
    SurfaceProp.shadow: 'Shadow',
    SurfaceProp.shadowColor: 'Shadow color',
  }),
  dialog('Dialog', 'DialogThemeData', {
    SurfaceProp.background: 'Background',
    SurfaceProp.borderColor: 'Border',
    SurfaceProp.borderWidth: 'Border width',
    SurfaceProp.radius: 'Radius',
    SurfaceProp.elevation: 'Elevation',
    SurfaceProp.titleStyle: 'Title style',
    SurfaceProp.bodyStyle: 'Content style',
    SurfaceProp.shadow: 'Shadow',
    SurfaceProp.shadowColor: 'Shadow color',
  }),
  bottomSheet('Bottom sheet', 'BottomSheetThemeData', {
    SurfaceProp.background: 'Background',
    SurfaceProp.radius: 'Radius (top corners)',
    SurfaceProp.elevation: 'Elevation',
    SurfaceProp.accent: 'Drag handle',
    SurfaceProp.shadow: 'Shadow',
    SurfaceProp.shadowColor: 'Shadow color',
  }),
  appBar('AppBar', 'AppBarThemeData', {
    SurfaceProp.background: 'Background',
    SurfaceProp.foreground: 'Text and icons',
    SurfaceProp.borderColor: 'Bottom border',
    SurfaceProp.borderWidth: 'Bottom border width',
    SurfaceProp.elevation: 'Elevation (also on scroll)',
    SurfaceProp.titleStyle: 'Title style',
  }),
  navigationBar('NavigationBar', 'NavigationBarThemeData', {
    SurfaceProp.background: 'Background',
    SurfaceProp.accent: 'Selection indicator',
    SurfaceProp.foreground: 'Selected icon',
    SurfaceProp.elevation: 'Elevation',
    SurfaceProp.height: 'Height',
    SurfaceProp.titleStyle: 'Label style',
    SurfaceProp.borderColor: 'Indicator border',
    SurfaceProp.borderWidth: 'Indicator border width',
    SurfaceProp.innerRadius: 'Indicator radius',
  }),
  navigationRail('NavigationRail', 'NavigationRailThemeData', {
    SurfaceProp.background: 'Background',
    SurfaceProp.accent: 'Selection indicator',
    SurfaceProp.foreground: 'Selected icon',
    SurfaceProp.titleStyle: 'Label style',
    SurfaceProp.borderColor: 'Indicator border',
    SurfaceProp.borderWidth: 'Indicator border width',
    SurfaceProp.innerRadius: 'Indicator radius',
  }),
  listTile('ListTile', 'ListTileThemeData', {
    SurfaceProp.titleStyle: 'Title style',
    SurfaceProp.bodyStyle: 'Subtitle style',
    SurfaceProp.foreground: 'Icons',
    SurfaceProp.accent: 'Selected background',
    SurfaceProp.radius: 'Radius',
  }),
  divider('Divider', 'DividerThemeData', {
    SurfaceProp.borderColor: 'Color',
    SurfaceProp.borderWidth: 'Thickness',
  }),
  fab('Floating action button', 'FloatingActionButtonThemeData', {
    SurfaceProp.background: 'Background',
    SurfaceProp.foreground: 'Icon and text',
    SurfaceProp.borderColor: 'Border',
    SurfaceProp.borderWidth: 'Border width',
    SurfaceProp.radius: 'Radius',
    SurfaceProp.elevation: 'Elevation',
    SurfaceProp.titleStyle: 'Label style (extended)',
    SurfaceProp.shadow: 'Shadow',
    SurfaceProp.shadowColor: 'Shadow color',
  }),
  tooltip('Tooltip', 'TooltipThemeData', {
    SurfaceProp.background: 'Background',
    SurfaceProp.foreground: 'Text',
    SurfaceProp.borderColor: 'Border',
    SurfaceProp.borderWidth: 'Border width',
    SurfaceProp.radius: 'Radius',
    SurfaceProp.shadow: 'Shadow (box-shadow)',
    SurfaceProp.bodyStyle: 'Text style',
    SurfaceProp.paddingH: 'Horizontal padding',
    SurfaceProp.paddingV: 'Vertical padding',
    SurfaceProp.shadowColor: 'Shadow color (if hard)',
  }),
  tabBar('TabBar', 'TabBarThemeData', {
    SurfaceProp.accent: 'Indicator and selected label',
    SurfaceProp.foreground: 'Unselected labels',
    SurfaceProp.borderWidth: 'Indicator thickness',
    SurfaceProp.borderColor: 'Divider below the tabs',
    SurfaceProp.titleStyle: 'Selected label style',
    SurfaceProp.bodyStyle: 'Unselected label style',
    SurfaceProp.paddingH: 'Label horizontal padding',
    SurfaceProp.background: 'Indicator fill (filled tab)',
    SurfaceProp.selectedForeground: 'Selected label on fill',
    SurfaceProp.innerRadius: 'Filled indicator radius',
  }),
  chip('Chip', 'ChipThemeData', {
    SurfaceProp.background: 'Background',
    SurfaceProp.foreground: 'Text and icons',
    SurfaceProp.accent: 'Selected background',
    SurfaceProp.selectedForeground: 'Selected text',
    SurfaceProp.borderColor: 'Border',
    SurfaceProp.borderWidth: 'Border width',
    SurfaceProp.radius: 'Radius',
    SurfaceProp.bodyStyle: 'Text style',
    SurfaceProp.paddingH: 'Horizontal padding',
    SurfaceProp.paddingV: 'Vertical padding',
    SurfaceProp.shadow: 'Shadow',
    SurfaceProp.shadowColor: 'Shadow color',
  }),
  badge('Badge', 'BadgeThemeData', {
    SurfaceProp.background: 'Background',
    SurfaceProp.foreground: 'Text',
    SurfaceProp.bodyStyle: 'Text style',
    SurfaceProp.height: 'Height (with a number)',
    SurfaceProp.paddingH: 'Horizontal padding',
  }),
  menu('Menus and dropdowns', 'MenuThemeData', {
    SurfaceProp.background: 'Panel background',
    SurfaceProp.borderColor: 'Panel border',
    SurfaceProp.borderWidth: 'Border width',
    SurfaceProp.radius: 'Panel radius',
    SurfaceProp.elevation: 'Elevation',
    SurfaceProp.paddingH: 'Panel padding',
    SurfaceProp.foreground: 'Item text',
    SurfaceProp.accent: 'Item background on hover',
    SurfaceProp.innerRadius: 'Item radius',
    SurfaceProp.paddingV: 'Item padding',
    SurfaceProp.bodyStyle: 'Item text style',
    SurfaceProp.shadow: 'Shadow',
    SurfaceProp.shadowColor: 'Shadow color',
  }),
  checkbox('Checkbox', 'CheckboxThemeData', {
    SurfaceProp.accent: 'Selected background',
    SurfaceProp.selectedForeground: 'Check mark',
    SurfaceProp.background: 'Unselected background',
    SurfaceProp.borderColor: 'Border',
    SurfaceProp.borderWidth: 'Border width',
    SurfaceProp.radius: 'Radius',
  }),
  radio('Radio', 'RadioThemeData', {
    SurfaceProp.accent: 'Selected color',
    SurfaceProp.borderColor: 'Unselected color',
    SurfaceProp.background: 'Inner background',
    SurfaceProp.selectedForeground: 'Selected inner background',
  }),
  switchControl('Switch', 'SwitchThemeData', {
    SurfaceProp.accent: 'Active track',
    SurfaceProp.background: 'Inactive track',
    SurfaceProp.foreground: 'Thumb',
    SurfaceProp.borderColor: 'Track outline',
    SurfaceProp.borderWidth: 'Outline width',
    SurfaceProp.selectedForeground: 'Thumb when on',
    // Geometry: if set, the theme includes AppSwitch (switch fully drawn,
    // with a thumb that can also be square).
    SurfaceProp.width: 'Width (AppSwitch)',
    SurfaceProp.height: 'Height (AppSwitch)',
    SurfaceProp.thumbSize: 'Thumb (AppSwitch)',
    SurfaceProp.radius: 'Track radius (AppSwitch)',
    SurfaceProp.innerRadius: 'Thumb radius (AppSwitch)',
    SurfaceProp.shadow: 'Thumb shadow (AppSwitch)',
    SurfaceProp.shadowColor: 'Shadow color',
  }),
  slider('Slider', 'SliderThemeData', {
    SurfaceProp.accent: 'Active track (start)',
    SurfaceProp.accentEnd: 'Active track (gradient end)',
    SurfaceProp.background: 'Inactive track',
    SurfaceProp.height: 'Track thickness',
    SurfaceProp.foreground: 'Cursor',
    SurfaceProp.borderColor: 'Thumb border',
    SurfaceProp.radius: 'Thumb radius',
    SurfaceProp.shadow: 'Thumb shadow',
    SurfaceProp.shadowColor: 'Shadow color (if hard)',
    SurfaceProp.innerRadius: 'Thumb corner radius (empty = round)',
    SurfaceProp.borderWidth: 'Track and thumb border',
    SurfaceProp.trackBorderWidth: 'Track border (empty = same as thumb)',
  }),
  snackBar('SnackBar', 'SnackBarThemeData', {
    SurfaceProp.background: 'Background',
    SurfaceProp.foreground: 'Text',
    SurfaceProp.accent: 'Action',
    SurfaceProp.borderColor: 'Border',
    SurfaceProp.borderWidth: 'Border width',
    SurfaceProp.radius: 'Radius',
    SurfaceProp.elevation: 'Elevation',
    SurfaceProp.bodyStyle: 'Text style',
    SurfaceProp.shadow: 'Shadow',
    SurfaceProp.shadowColor: 'Shadow color',
  });

  const SurfaceKind(this.label, this.themeData, this.props);

  final String label;
  final String themeData;

  /// Supported properties, with the label to show in the editor.
  final Map<SurfaceProp, String> props;

  /// Material 3 default radius.
  double get m3Radius => switch (this) {
    card => 12,
    fab => 16,
    tooltip || menu => 4,
    checkbox => 2,
    slider => 10,
    chip => 8,
    dialog || bottomSheet => 28,
    snackBar => 4,
    _ => 0,
  };

  double get m3Elevation => switch (this) {
    card => 1,
    dialog => 6,
    bottomSheet => 1,
    navigationBar => 3,
    fab => 6,
    menu => 3,
    snackBar => 6,
    _ => 0,
  };
}

/// Container override. `null` = Material 3 default.
class SurfaceConfig {
  ColorRef? background;
  ColorRef? foreground;
  ColorRef? borderColor;
  double? borderWidth;
  double? radius;
  double? elevation;
  ColorRef? accent;
  TextRole? titleStyle;
  TextRole? bodyStyle;
  double? height;
  ShadowToken? shadow;
  double? paddingH;
  double? paddingV;
  double? innerRadius;
  ColorRef? selectedForeground;
  ColorRef? accentEnd;

  /// Hard shadow color (default: the scheme's outline).
  ColorRef? shadowColor;
  double? width;
  double? thumbSize;

  /// Slider only: track border width (null = [borderWidth]).
  double? trackBorderWidth;

  bool get isEmpty =>
      background == null &&
      foreground == null &&
      borderColor == null &&
      borderWidth == null &&
      radius == null &&
      elevation == null &&
      accent == null &&
      titleStyle == null &&
      bodyStyle == null &&
      height == null &&
      shadow == null &&
      paddingH == null &&
      paddingV == null &&
      innerRadius == null &&
      selectedForeground == null &&
      accentEnd == null &&
      shadowColor == null &&
      width == null &&
      thumbSize == null &&
      trackBorderWidth == null;

  bool get hasBorder => borderColor != null || borderWidth != null;

  /// Hard shadow drawn by the shape (HardShadowBorder).
  bool get hasHardShadow => shadow?.isHard ?? false;

  /// Any shadow drawn by the shape (hard or soft CSS-style).
  bool get hasShapeShadow => shadow != null && shadow != ShadowToken.none;

  void reset() {
    background = null;
    foreground = null;
    borderColor = null;
    borderWidth = null;
    radius = null;
    elevation = null;
    accent = null;
    titleStyle = null;
    bodyStyle = null;
    height = null;
    shadow = null;
    paddingH = null;
    paddingV = null;
    innerRadius = null;
    selectedForeground = null;
    accentEnd = null;
    shadowColor = null;
    width = null;
    thumbSize = null;
    trackBorderWidth = null;
  }

  /// The switch has its own geometry: AppSwitch is needed.
  bool get hasSwitchGeometry =>
      width != null ||
      height != null ||
      thumbSize != null ||
      radius != null ||
      innerRadius != null ||
      shadow != null;
}
