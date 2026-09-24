import 'package:flutter/widgets.dart';

/// True when keyboard focus is inside a text field.
bool isTextInputFocused() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  if (ctx.widget is EditableText) return true;
  return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// Action that is disabled while typing in a text field, so single-key and
/// global shortcuts never fire mid-typing. Esc should not use this.
class GuardedAction<T extends Intent> extends CallbackAction<T> {
  GuardedAction({required super.onInvoke});

  @override
  bool isEnabled(T intent) => !isTextInputFocused();

  // Let the key reach the text field when disabled.
  @override
  bool consumesKey(T intent) => isEnabled(intent);
}
