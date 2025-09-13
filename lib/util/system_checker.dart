class SystemCheckerReturn {
  final bool _isError;
  final String _errorString;

  SystemCheckerReturn(this._isError, this._errorString);
  get errorString => _errorString;
  get isError => _isError;
}

class SystemChecker {
  SystemCheckerReturn? checkWebsocketPort() {
    return null;
  }

  SystemCheckerReturn? checkBluetoothOn() {
    return null;
  }

  List<SystemCheckerReturn> runSystemChecks() {
    return List.empty();
  }
}
