import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// スワイプバックを無効化したPageRoute
class NoSwipePageRoute<T> extends MaterialPageRoute<T> {
  NoSwipePageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
          builder: builder,
          settings: settings,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // フェードトランジション
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  @override
  bool get hasScopedWillPopCallback => true;

  @override
  bool get popGestureEnabled => false; // スワイプバックを無効化
}