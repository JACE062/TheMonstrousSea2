import 'dart:convert';
import 'dart:io';

import 'package:monstrous_core/monstrous_core.dart';
import 'package:monstrous_sim/monstrous_sim.dart';

void main(List<String> args) {
  if (args.isEmpty) throw ArgumentError('Supply a new JSON output path.');
  final output = File(args.first);
  if (output.existsSync()) throw StateError('Receipt already exists.');
  final rows = <Map<String, dynamic>>[];
  for (var region = 0; region < 3; region++) {
    for (final capped in [false, true]) {
      for (final combined in [false, true]) {
        for (final condition in WreckCondition.values) {
          for (var i = 0; i < 100; i++) {
            rows.add(
              auditMatchedEncounter(
                seed: 20261105 + 31 * i,
                region: region,
                capped: capped,
                condition: condition,
                combinedHealing: combined,
              ),
            );
          }
        }
      }
    }
  }
  output.parent.createSync(recursive: true);
  final encoded = jsonEncode(rows);
  if (output.path.endsWith('.gz')) {
    output.writeAsBytesSync(gzip.encode(utf8.encode(encoded)));
  } else {
    output.writeAsStringSync(encoded);
  }
  stdout.writeln(
    '${rows.length} matched encounters; ${rows.where((r) => r['won'] == true).length} won pairs.',
  );
}
