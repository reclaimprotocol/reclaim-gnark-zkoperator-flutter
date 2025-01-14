import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gnarkprover/gnarkprover.dart';
import 'package:reclaim_flutter_sdk/attestor_webview.dart';
import 'package:reclaim_flutter_sdk/logging/data/log.dart';
import 'package:reclaim_flutter_sdk/logging/logging.dart';
import 'package:reclaim_flutter_sdk/reclaim_flutter_sdk.dart';
import 'package:reclaim_flutter_sdk/utils/keys.dart';
import 'package:uuid/uuid.dart';

import 'build_env.dart';
import 'widgets/progress.dart';
import 'screen/debug_webview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Setting this to true will print logs from reclaim_flutter_sdk to the console.
  debugCanPrintLogs = true;
  initializeReclaimLogging();
  Gnarkprover.getInstance().then((gnarkProver) {
    Attestor.instance.computeAttestorProof = gnarkProver.computeAttestorProof;
    AttestorWebview.instance.computeAttestorProof =
        gnarkProver.computeAttestorProof;
  });
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

enum ClaimCreationState {
  idle,
  creating,
  created,
  error,
}

class _TestScreenState extends State<TestScreen> {
  String sessionId = '';

  @override
  void initState() {
    super.initState();
    generateSessionId();
  }

  void generateSessionId() {
    final String generatedSessionId = const Uuid().v4().toString();
    sessionId = generatedSessionId;
    latestConsumerIdentity = ConsumerIdentity(
      appId: BuildEnv.APP_ID,
      sessionId: generatedSessionId,
      providerId: 'none',
    );
    if (mounted) {
      setState(() {
        //
      });
    }
  }

  void openAttestorUrlInWebView() {
    DebugWebviewScreen.open(context,
        initialUrl: AttestorWebview.instance.attestorUrl);
  }

  void setup() {
    logging.level = Level.ALL;
    Attestor.instance.setAttestorDebugLevel('debug');
    AttestorWebview.instance.setAttestorDebugLevel('debug');
  }

  final TextEditingController textEditingController = TextEditingController(
    // A claim creation json args can be supplied as an initial json string assigned here to the [text] property to pre-fill the textfield.
    // Just restart the app to see the effect.
    text: null,
  );

  ClaimCreationState claimCreationState = ClaimCreationState.idle;

  void updateState(ClaimCreationState state) {
    claimCreationState = state;
    if (mounted) {
      setState(() {});
    }
  }

  double _proofGenerationProgress = 0;

  void _onClaimCreationUpdate(Map? step) {
    if (step == null) return;
    if (step["step"]["name"] != 'witness-progress') return;
    final info = step['step']['step'];
    double proofGenerationProgress() {
      try {
        final done = info['proofsDone'] ?? 0;
        final total = info['proofsTotal'] ?? 10;
        final progress = done / total;
        return Tween<double>(
          begin: 0.4,
          end: 0.9,
        ).transform(progress);
      } catch (e, s) {
        logging.child('ClaimCreationBottomSheetState._onStepChange').severe(
              'Failed to update progress notifier when step was $step',
              e,
              s,
            );
        return _proofGenerationProgress;
      }
    }

    _proofGenerationProgress = switch (info['name']) {
      'connecting' => 0.1,
      'sending-request-data' => 0.2,
      'waiting-for-response' => 0.3,
      'generating-zk-proofs' => proofGenerationProgress(),
      'waiting-for-verification' => 1.0,
      _ => _proofGenerationProgress,
    };
    if (mounted) {
      setState(() {});
    }
  }

  void startClaimCreation() async {
    final logger = logging.child('TestScreen.startClaimCreation');

    final messenger = ScaffoldMessenger.of(context);
    final ownerPrivateKey = await getReclaimPrivateKeyOfOwner();
    final Map<String, dynamic> claimCreationParams = {
      ...json.decode(textEditingController.text),
      "sessionId": sessionId,
      "ownerPrivateKey": ownerPrivateKey,
      "updateProviderParams": false,
    };
    try {
      updateState(ClaimCreationState.creating);
      logger.info('Waiting for gnarkprover to initialize');
      await Gnarkprover.getInstance();
      logger.info('Gnarkprover initialized');

      final proof = await Attestor.instance.createClaim(
        claimCreationParams,
        _onClaimCreationUpdate,
        options: const CreateClaimOptions(isComputeProofLocalEnabled: true),
      );
      logger.info(json.encode({
        'proof': proof,
      }));
      updateState(ClaimCreationState.created);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Claim created'),
        ),
      );
    } catch (e, s) {
      logger.severe('Error creating claim', e, s);
      updateState(ClaimCreationState.error);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Error creating claim: ${e.toString()}',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test screen'),
      ),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            const GnarkProverInitStatusTile(),
            ListTile(
              onTap: () {
                Clipboard.setData(ClipboardData(text: sessionId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Session ID copied to clipboard'),
                  ),
                );
              },
              title: Text(sessionId),
              subtitle: const Text('Session ID'),
              trailing: IconButton(
                onPressed: generateSessionId,
                icon: const Icon(Icons.refresh),
              ),
            ),
            Row(
              spacing: 4,
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: openAttestorUrlInWebView,
                    child: const Text(
                      'Check in Web',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: setup,
                    child: const Text(
                      'Enable debug logs',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 4,
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: pasteArgsInTextFieldFromClipboard,
                    child: const Text(
                      'Paste Args',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: clearArgsFromTextField,
                    child: const Text(
                      'Clear Args',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: textEditingController,
              decoration: const InputDecoration(
                labelText: 'Enter Claim Creation Params in JSON',
              ),
              textInputAction: TextInputAction.done,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'This field requires a claim creation params as a json string';
                }
                try {
                  json.decode(value);
                } catch (_) {
                  return 'The provided value is not a valid JSON';
                }
                return null;
              },
            ),
            Builder(
              builder: (context) {
                return FilledButton(
                  onPressed: () {
                    if (!Form.of(context).validate()) return;
                    startClaimCreation();
                  },
                  child: const Text('Start Claim Creation'),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClaimStepProgressIndicator(
                progress: _proofGenerationProgress,
                color: () {
                  switch (claimCreationState) {
                    case ClaimCreationState.creating:
                      return Colors.blue;
                    case ClaimCreationState.created:
                      return Colors.green;
                    case ClaimCreationState.error:
                      return Colors.red;
                    case ClaimCreationState.idle:
                      return Colors.grey;
                  }
                }(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void clearArgsFromTextField() => textEditingController.clear();

  void pasteArgsInTextFieldFromClipboard() async {
    textEditingController.text =
        (await Clipboard.getData('text/plain'))?.text ?? '';
  }
}

class GnarkProverInitStatusTile extends StatelessWidget {
  const GnarkProverInitStatusTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Gnarkprover.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ListTile(
            leading: Icon(Icons.error),
            title: Text(
              'Failed to initialize Gnark Prover',
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(),
            ),
            title: Text(
              'Initializing Gnark Prover',
            ),
          );
        }
        return const ListTile(
          leading: Icon(Icons.check),
          title: Text(
            'GnarkProver initialized',
          ),
        );
      },
    );
  }
}
