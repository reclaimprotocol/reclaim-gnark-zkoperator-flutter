#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:version/version.dart';
import 'package:yaml_edit/yaml_edit.dart' as yaml;

void main() {
  final pubFile = File('pubspec.yaml');
  final pubDocument = yaml.YamlEditor(pubFile.readAsStringSync());
  final oldVersion = pubDocument.parseAt(['version']).value;
  final version = Version.parse(oldVersion).incrementPatch();
  pubDocument.update(['version'], version.toString());
  print('Bumping version from $oldVersion to $version');
  pubFile.writeAsStringSync(pubDocument.toString());
}
