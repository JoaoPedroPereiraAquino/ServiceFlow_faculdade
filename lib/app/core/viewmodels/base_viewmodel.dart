// Estados comuns (parado, carregando, certo, erro) para as telas.

import 'package:flutter/foundation.dart';

enum ViewState { idle, loading, success, error }

abstract class BaseViewModel<T> extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  ViewState get state => _state;

  T? data;
  String? errorMessage;

  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;

  void setLoading() {
    _state = ViewState.loading;
    errorMessage = null;
    notifyListeners();
  }

  void setSuccess([T? value]) {
    _state = ViewState.success;
    if (value != null) data = value;
    errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _state = ViewState.error;
    errorMessage = message;
    notifyListeners();
  }

  void reset() {
    _state = ViewState.idle;
    errorMessage = null;
    notifyListeners();
  }
}
