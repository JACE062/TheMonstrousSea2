import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:monstrous_core/monstrous_core.dart';

import 'storage_service.dart';

class LineageSlot {
  const LineageSlot({required this.id, required this.label});
  final String id;
  final String label;

  Map<String, Object> toJson() => {'id': id, 'label': label};
}

class LineageCatalog {
  LineageCatalog(Iterable<LineageSlot> slots, {this.activeId})
    : slots = List.unmodifiable(slots);

  final List<LineageSlot> slots;
  final String? activeId;
  Map<String, Object?> toJson() => {
    'version': 1,
    'activeId': activeId,
    'slots': slots.map((slot) => slot.toJson()).toList(),
  };

  factory LineageCatalog.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 || json['slots'] is! List) {
      throw const FormatException('Unsupported lineage catalog');
    }
    final slots = <LineageSlot>[];
    final ids = <String>{};
    for (final entry in json['slots'] as List) {
      if (entry is! Map<String, dynamic> ||
          entry['id'] is! String ||
          entry['label'] is! String) {
        throw const FormatException('Invalid lineage entry');
      }
      final id = entry['id'] as String;
      final label = entry['label'] as String;
      if (!RegExp(r'^[a-z0-9-]{1,64}$').hasMatch(id) ||
          !ids.add(id) ||
          label.trim().isEmpty ||
          label.length > 60) {
        throw const FormatException('Invalid lineage identity');
      }
      slots.add(LineageSlot(id: id, label: label));
    }
    final activeId = json['activeId'];
    if (activeId != null && (activeId is! String || !ids.contains(activeId))) {
      throw const FormatException('Unknown selected lineage');
    }
    return LineageCatalog(slots, activeId: activeId as String?);
  }
}

class LineageSummary {
  const LineageSummary(this.slot, {this.profile, this.error});
  final LineageSlot slot;
  final ProfileData? profile;
  final String? error;
  bool get readable => error == null;
  String get description {
    if (error != null) return error!;
    if (profile!.hasShatteredFont) return 'Completed hunt · Ending preserved';
    if (!profile!.hasBegunFirstVoyage) {
      return 'A new bloodline awaits its captain';
    }
    return '${profile!.lineageTracker.captainsLost} captains lost'
        '${profile!.hasUnlockedCovenant ? ' · Covenant awakened' : ''}';
  }
}

/// Slot identities never derive from user-entered labels or captain surnames.
/// The catalog is published only after a complete initial profile/save copy.
class LineageStore {
  LineageStore({StorageService? rootStorage})
    : rootStorage = rootStorage ?? StorageService();

  final StorageService rootStorage;
  static const catalogName = 'lineages.json';
  Future<void> _pending = Future.value();

  Future<T> _serial<T>(Future<T> Function() action) {
    final operation = _pending.then((_) => action());
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> _atomicWrite(File target, List<int> bytes) async {
    await target.parent.create(recursive: true);
    final pending = File('${target.path}.pending');
    await pending.writeAsBytes(bytes, flush: true);
    await pending.rename(target.path);
  }

  Future<void> _saveCatalog(Directory root, LineageCatalog catalog) =>
      _atomicWrite(
        File('${root.path}/$catalogName'),
        utf8.encode(jsonEncode(catalog.toJson())),
      );

  Directory _slotDirectory(Directory root, LineageSlot slot) =>
      Directory('${root.path}/lineages/${slot.id}');

  StorageService _storage(Directory root, LineageSlot slot) => StorageService(
    baseDirectory: _slotDirectory(root, slot),
    strictReads: true,
  );

  Future<LineageCatalog> _catalog(Directory root) async {
    final file = File('${root.path}/$catalogName');
    final importPending = File('${root.path}/.lineages_import_pending');
    if (await file.exists()) {
      final catalog = LineageCatalog.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
      if (await importPending.exists()) await importPending.delete();
      return catalog;
    }
    // A directory at the catalog path is an error, never an empty catalog.
    if (await FileSystemEntity.type(file.path) !=
        FileSystemEntityType.notFound) {
      throw const FileSystemException('The lineage catalog is unavailable');
    }
    final lineages = Directory('${root.path}/lineages');
    if (await lineages.exists() &&
        !(await lineages.list().isEmpty) &&
        !await importPending.exists()) {
      throw const FormatException('Existing lineages have no catalog');
    }
    final profileFile = File('${root.path}/${StorageService.profileFileName}');
    final voyageFile = File('${root.path}/${StorageService.voyageFileName}');
    final hasProfile = await profileFile.exists();
    final hasVoyage = await voyageFile.exists();
    final original = const LineageSlot(
      id: 'original',
      label: 'Original Lineage',
    );
    if (hasProfile || hasVoyage) {
      if (!hasProfile) {
        throw const FormatException('Voyage has no matching profile');
      }
      // Validate the pair before publishing it. Sources remain untouched backups.
      final profileBytes = await profileFile.readAsBytes();
      ProfileData.fromJson(
        jsonDecode(utf8.decode(profileBytes)) as Map<String, dynamic>,
      );
      final voyageBytes = hasVoyage ? await voyageFile.readAsBytes() : null;
      if (voyageBytes != null) {
        VoyageSaveData.fromJson(
          jsonDecode(utf8.decode(voyageBytes)) as Map<String, dynamic>,
        );
      }
      final directory = _slotDirectory(root, original);
      await _atomicWrite(importPending, utf8.encode('1'));
      await _atomicWrite(
        File('${directory.path}/${StorageService.profileFileName}'),
        profileBytes,
      );
      if (voyageBytes != null) {
        await _atomicWrite(
          File('${directory.path}/${StorageService.voyageFileName}'),
          voyageBytes,
        );
      }
    }
    final catalog = LineageCatalog(
      hasProfile ? [original] : [],
      activeId: hasProfile ? original.id : null,
    );
    await _saveCatalog(root, catalog);
    if (await importPending.exists()) await importPending.delete();
    return catalog;
  }

  Future<LineageCatalog> load() => _serial(() async {
    final root = await rootStorage.initializeDirectory();
    return _catalog(root);
  });

  Future<List<LineageSummary>> summaries() => _serial(() async {
    final root = await rootStorage.initializeDirectory();
    final catalog = await _catalog(root);
    final results = <LineageSummary>[];
    for (final slot in catalog.slots) {
      try {
        final storage = _storage(root, slot);
        await _requireProfile(root, slot);
        final profile = await storage.loadProfile();
        final voyage = await storage.loadVoyage();
        if (voyage != null) profile.hasBegunFirstVoyage = true;
        results.add(LineageSummary(slot, profile: profile));
      } catch (_) {
        results.add(
          LineageSummary(
            slot,
            error: 'Save could not be read. Restore a backup and retry.',
          ),
        );
      }
    }
    return results;
  });

  Future<void> _requireProfile(Directory root, LineageSlot slot) async {
    if (!await File(
      '${_slotDirectory(root, slot).path}/${StorageService.profileFileName}',
    ).exists()) {
      throw const FileSystemException('Lineage profile is missing');
    }
  }

  Future<LineageSlot> create(String label) => _serial(() async {
    final trimmed = label.trim();
    if (trimmed.isEmpty || trimmed.length > 60) {
      throw ArgumentError('Use a save label of 1–60 characters');
    }
    final root = await rootStorage.initializeDirectory();
    final catalog = await _catalog(root);
    final id =
        'lineage-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(0x7fffffff).toRadixString(16)}';
    final slot = LineageSlot(id: id, label: trimmed);
    // Refuse a collision rather than reusing an existing lineage directory.
    final directory = _slotDirectory(root, slot);
    if (await directory.exists()) {
      throw StateError('Lineage identity already exists');
    }
    await _storage(root, slot).saveProfile(ProfileData());
    await _saveCatalog(
      root,
      LineageCatalog([...catalog.slots, slot], activeId: slot.id),
    );
    return slot;
  });

  Future<StorageService> open(String id) => _serial(() async {
    final root = await rootStorage.initializeDirectory();
    final catalog = await _catalog(root);
    final slot = catalog.slots.where((slot) => slot.id == id).firstOrNull;
    if (slot == null) throw ArgumentError('Unknown lineage');
    await _requireProfile(root, slot);
    final storage = _storage(root, slot);
    await storage.loadProfile();
    await storage.loadVoyage();
    await _saveCatalog(root, LineageCatalog(catalog.slots, activeId: id));
    return storage;
  });
}
