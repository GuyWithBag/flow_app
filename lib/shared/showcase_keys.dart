import 'package:flutter/widgets.dart';

/// Static GlobalKeys used by ShowcaseView to highlight key timer UI elements.
/// These are static so they can be referenced from both timer_page.dart
/// (where Showcase widgets live) and from anywhere that calls startShowCase().
class ShowcaseKeys {
  ShowcaseKeys._();

  static final GlobalKey topControls = GlobalKey();
  static final GlobalKey modeToggle = GlobalKey();
  static final GlobalKey timerCircle = GlobalKey();
  static final GlobalKey bottomControls = GlobalKey();

  static List<GlobalKey> get all => [
    topControls,
    modeToggle,
    timerCircle,
    bottomControls,
  ];
}
