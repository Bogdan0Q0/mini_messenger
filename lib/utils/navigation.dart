import 'package:flutter/material.dart';

/// Открывает экран и следит за фокусом ввода.
///
/// Если перед переходом в поле (например, поиска) стоял курсор, Flutter
/// запоминает его и при возврате снова ставит фокус туда — клавиатура
/// появляется сама. Поэтому фокус снимается до перехода и после возврата.
Future<T?> pushScreen<T>(BuildContext context, Widget screen) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final result = await Navigator.of(context).push<T>(
    MaterialPageRoute<T>(builder: (_) => screen),
  );
  FocusManager.instance.primaryFocus?.unfocus();
  return result;
}
