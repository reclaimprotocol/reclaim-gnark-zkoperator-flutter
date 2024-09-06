# gnarkprover

Reclaim Protocol's library for creating Gnark Proof. This can be optionally used in [Reclaim's Flutter SDK](https://gitlab.reclaimprotocol.org/integrations/offchain/reclaim_flutter_sdk.git) for creating proof with gnark.

## Getting Started

### Use this package with the reclaim_flutter_sdk

You can use the reclaim flutter sdk with the experimental gnark prover to compute the witness proof *faster* locally.

#### Add the `gnarkprover` dependency

Run this command:

With Flutter:
```sh
 $ flutter pub add gnarkprover
```

This will add a line like this to your package's pubspec.yaml (and run an implicit flutter pub get):

```yaml
dependencies:
  gnarkprover: ^0.1.0
```

#### Import it

Now in your Dart code, you can use:

```dart
import 'package:gnarkprover/gnarkprover.dart';
```

#### Example of using the reclaim flutter sdk with gnark prover

```dart
import 'package:flutter/material.dart';
import 'package:reclaim_flutter_sdk/reclaim_flutter_sdk.dart';

// An optional dependency that can be used with reclaim_flutter_sdk to compute the witness proof locally.
import 'package:gnarkprover/gnarkprover.dart';

const String appId = 'YOUR_APPLICATION_ID_HERE';
const String appSecret = 'YOUR_APP_SECRET_HERE';
const String providerId = 'YOUR_PROVIDER_ID_HERE';

void main() async {
  runApp(const MaterialApp(
    home: Example(),
  ));
}

class Example extends StatelessWidget {
  const Example({super.key});

  void onStartClaimWithGnarkProverButtonPressed(BuildContext context) async {
    final msg = ScaffoldMessenger.of(context);
    try {
      // Getting the Gnark prover instance to initialize in advance before usage because initialization can take time.
      // This can also be done in the `main` function.
      // Calling this more than once is safe.
      Gnarkprover.getInstance();

      // Enable the use of the local prover in the reclaim SDK (because it is disabled by default).
      setComputeProofLocal(true);

      final reclaimVerification = ReclaimVerification(
       buildContext: context, // This widget's build contex
        appId: appId, // your application identifier from the dev tool
        providerId: providerId, // your provider identifier from the dev tool
        secret: appSecret, // your secret token of your application from the dev tool
        context: '', // your claim context
        parameters: { /* ... */ }, // parameters to pre-inject in the provider response selections
        // Pass the computeWitnessProof callback to the sdk. This can be optionally used to compute the witness proof externally.
        // For example, we can use the gnark prover to compute the witness proof locally.
        // Note: This is an optional parameter. And use of this parameter is disabled by default. To enable, invoke `setComputeProofLocal(true)`
        computeWitnessProof: (type, bytes) async {
          // Get gnark prover instance and compute the witness proof.
          return (await Gnarkprover.getInstance())
              .computeWitnessProof(type, bytes);
        },
        hideLanding: true,
      );
      final proofs = await reclaimVerification.startVerification();
      print("Proofs: ${proofs?.toJson()}");
      msg.removeCurrentSnackBar();
      if (proofs == null) {
        msg.showSnackBar(
          const SnackBar(
            content: Text('example verification closed'),
          ),
        );
      } else {
        msg.showSnackBar(
          const SnackBar(
            content: Text('example verification completed'),
          ),
        );
      }
    } catch (error, stackTrace) {
      print("Failed to start verification\n$error\n$stackTrace");
      msg.removeCurrentSnackBar();
      msg.showSnackBar(
        const SnackBar(
          content: Text('Failed example verification'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reclaim SDK Example'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton(
            onPressed: () {
              onStartClaimWithGnarkProverButtonPressed(context);
            },
            child: const Text('Start Claim with Gnark Prover'),
          ),
        ],
      ),
    );
  }
}
```

#### Try the Reclaim's Flutter SDK Example

1. Try the example from [Reclaim's Flutter SDK Example](https://gitlab.reclaimprotocol.org/integrations/offchain/reclaim_flutter_sdk/-/tree/main/example).
2. This example uses `gnarkprover` package to compute witness proof locally. This is optional and `reclaim_flutter_sdk` can be used without it.
3. To run the example, follow the instructions in the [Reclaim's Flutter SDK Example README](https://gitlab.reclaimprotocol.org/integrations/offchain/reclaim_flutter_sdk/-/blob/main/example/README.md).

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
