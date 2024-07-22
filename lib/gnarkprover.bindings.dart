part of 'gnarkprover.dart';

const String _libName = 'gnarkprover';

/// The dynamic library in which the symbols for [GnarkProverBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final GnarkProverBindings _bindings = GnarkProverBindings(_dylib);
