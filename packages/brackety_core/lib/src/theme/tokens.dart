abstract final class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class AppRadius {
  // Short corners, never pills: buttons and mats are rectangles.
  static const double s = 4;
  static const double m = 6;
  static const double l = 8;
  static const double xl = 12;
  static const double full = 999;
}

abstract final class AppSizes {
  static const double touchTarget = 48;
  // Buttons a little taller than the minimum target: they are the place to press.
  static const double buttonHeight = 52;
  // Scoreboard buttons are pressed in a hurry, one-handed, at arm's length.
  static const double scoreTouchTarget = 72;
  // Icons on those buttons: recognisable at a glance from the side of the mat.
  static const double scoreIcon = 40;
  // Short forms (sign-in, sign-up) stay readable on wide windows instead of stretching.
  static const double formMaxWidth = 480;
  // Long texts (legal pages): a comfortable line length on wide windows.
  static const double readingMaxWidth = 720;
  // On phones a wide table keeps readable columns and scrolls sideways instead of squeezing.
  static const double compactTableColumnWidth = 200;
}
