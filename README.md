# gnarkprover

Reclaim Protocol's library for creating Gnark Proof. This can be optionally used in [Reclaim's Flutter SDK](https://gitlab.reclaimprotocol.org/integrations/offchain/reclaim_flutter_sdk.git) for creating proof with gnark.

## Project structure

This template uses the following structure:

* `example`: Contains a simple example demonstrating the use of `proveSync`, and `proveAsync` for generating proof on android & ios.

* `src`: Contains the scripts and a `Makefile` for building
  the reclaimprotocol.org's gnark prover golang source code into a dynamic library.

* `lib`: Contains the Dart code that defines the API of the plugin, and which
  calls into the native code using `dart:ffi`.

* platform folders (`android`, `ios`, etc.): Contains the build files
  for building and bundling the native code library with the platform application.

## Building and bundling native code

The `pubspec.yaml` specifies FFI plugins as follows:

```yaml
  plugin:
    platforms:
      some_platform:
        ffiPlugin: true
```

This configuration invokes the native build for the various target platforms
and bundles the binaries in Flutter applications using these FFI plugins.

This can be combined with dartPluginClass, such as when FFI is used for the
implementation of one platform in a federated plugin:

```yaml
  plugin:
    implements: some_other_plugin
    platforms:
      some_platform:
        dartPluginClass: SomeClass
        ffiPlugin: true
```

A plugin can have both FFI and method channels:

```yaml
  plugin:
    platforms:
      some_platform:
        pluginClass: SomeName
        ffiPlugin: true
```

The native build systems that are invoked by FFI (and method channel) plugins are:

* For Android: Gradle, which invokes the Android NDK for native builds.
  * See the documentation in android/build.gradle.
* For iOS: Xcode, via CocoaPods.
  * See the documentation in ios/gnarkprover.podspec.

### Buidling native binaries

The native dynamic libraries, which will be used by android and ios native build systems, can be regenerated from inside the `src` directory. These native dynamic libraries are currently built from reclaimprotocol's gnark prover golang code.

To build for ios, run `make ios` inside `src`.
To build for android, run `make android` inside `src`.   

## Binding to native binary

To use the native binary, bindings in Dart are needed.
To avoid writing these by hand, they can be generated from inside `src` directory by `package:ffigen`.
Regenerate the bindings by running `make gen_bindings` inside `src` directory.

## Invoking native code

The function `initializeSync` must be called atleast once before using any other function from the library.

The function `proveSync` can be directly invoked from any isolate for generating proof. If this results in dropping frames in Flutter applications, use `proveAsync` which invokes proveSync on a helper isolate.
