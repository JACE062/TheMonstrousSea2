import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:monstrous_core/monstrous_core.dart';
import 'package:path_provider/path_provider.dart';

/// Service managing persistent disk storage for player profile and transient voyage saves.
///
/// Implements dual-file anti-scumming architecture:
/// - `player_profile.json`: Persistent profile (meta-inventory, lineage history, nemesis, town progress).
/// - `voyage_save.json`: Encounter/ending checkpoint. Ordinary death and home
///   preparation clear it; resolved Caldera prose and offered heirs can resume.
class StorageService {
  StorageService({Directory? baseDirectory, this.legacyDirectory})
    : baseDirectory =
          baseDirectory ??
          (Zone.current[_isolatedDirectoryKey] as Directory?) ??
          testDefaultDirectory;

  /// Test-harness fallback across test-runner zones. Production leaves this
  /// null; fixtures still prefer explicit directories or disabled autosave.
  static Directory? testDefaultDirectory;

  static const _isolatedDirectoryKey = #monstrousSeaIsolatedStorage;

  /// Scope default services to isolated storage, including asynchronous work.
  /// Explicit constructor directories still take precedence. An injected base
  /// disables legacy migration unless a legacy directory is explicitly supplied.
  static R withIsolatedStorage<R>(Directory directory, R Function() action) =>
      runZoned(action, zoneValues: {_isolatedDirectoryKey: directory});

  /// Explicit storage directories isolate tests from the player's real saves.
  /// Migration is disabled for an injected base unless a legacy source is given.
  final Directory? baseDirectory;
  final Directory? legacyDirectory;
  Future<Directory>? _directoryFuture;

  static const String profileFileName = 'player_profile.json';
  static const String voyageFileName = 'voyage_save.json';
  static const String _migrationComplete = '.legacy_migration_complete';
  static const String _migrationPending = '.legacy_migration_pending.json';
  static const _saveFileNames = [profileFileName, voyageFileName];

  static File _fileIn(Directory directory, String name) =>
      File('${directory.path}${Platform.pathSeparator}$name');

  /// Resolves the production path without reading, creating, or migrating saves.
  static Future<Directory> defaultSaveDirectory() async {
    final Directory root;
    if (Platform.isWindows) {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData == null || localAppData.trim().isEmpty) {
        throw const FileSystemException('LOCALAPPDATA is unavailable');
      }
      root = Directory(localAppData);
    } else {
      root = await getApplicationSupportDirectory();
    }
    return Directory(
      '${root.path}${Platform.pathSeparator}TheMonstrousSea2'
      '${Platform.pathSeparator}Saves',
    );
  }

  Future<Directory> _resolveDirectory() async {
    final initialization = _directoryFuture ??= _prepareDirectory();
    try {
      return await initialization;
    } catch (_) {
      if (identical(_directoryFuture, initialization)) _directoryFuture = null;
      rethrow;
    }
  }

  Future<Directory> _prepareDirectory() async {
    final directory = baseDirectory ?? await defaultSaveDirectory();
    await directory.create(recursive: true);
    if (baseDirectory == null || legacyDirectory != null) {
      await _migrateLegacySaves(directory);
    }
    return directory;
  }

  Future<Directory?> _findLegacyDirectory() async {
    final injected = legacyDirectory;
    if (injected != null) return injected;

    // The previous implementation used Documents, falling back to system temp
    // when the platform lookup failed. Import a single source, never mix them.
    final candidates = <Directory>[];
    try {
      candidates.add(await getApplicationDocumentsDirectory());
    } catch (_) {
      /* A legacy temp save may still exist. */
    }
    candidates.add(Directory.systemTemp);
    for (final candidate in candidates) {
      for (final name in _saveFileNames) {
        if (await _fileIn(candidate, name).exists()) return candidate;
      }
    }
    return null;
  }

  Future<void> _migrateLegacySaves(Directory destination) async {
    final complete = _fileIn(destination, _migrationComplete);
    if (await complete.exists()) return;
    final pending = _fileIn(destination, _migrationPending);

    final Map<String, dynamic> migration;
    if (await pending.exists()) {
      // A failed/interrupted import owns its partial destination files. Resume
      // it before allowing any game reads/writes, rather than loading half a pair.
      migration =
          jsonDecode(await pending.readAsString()) as Map<String, dynamic>;
    } else {
      // New-location saves are authoritative, even if only one exists. In
      // particular, never resurrect an old voyage beside a newer profile.
      for (final name in _saveFileNames) {
        if (await _fileIn(destination, name).exists()) {
          await complete.writeAsString('1', flush: true);
          return;
        }
      }
      final source = await _findLegacyDirectory();
      final names = <String>[];
      if (source != null) {
        for (final name in _saveFileNames) {
          if (await _fileIn(source, name).exists()) names.add(name);
        }
      }
      migration = {'source': source?.absolute.path, 'files': names};
      await pending.writeAsString(jsonEncode(migration), flush: true);
    }

    final names = (migration['files'] as List).cast<String>();
    for (final name in names) {
      if (!_saveFileNames.contains(name)) {
        throw const FormatException('Invalid legacy save filename');
      }
      final source = Directory(migration['source'] as String);
      final bytes = await _fileIn(source, name).readAsBytes();
      await _fileIn(destination, name).writeAsBytes(bytes, flush: true);
    }
    // Keep originals untouched as backups. The marker prevents re-import after
    // death, voyage deletion, or an intentional reset of the new save files.
    await complete.writeAsString('1', flush: true);
    await pending.delete();
  }

  Future<File> _getFile(String fileName) async {
    final dir = await _resolveDirectory();
    return _fileIn(dir, fileName);
  }

  /// Loads the persistent [ProfileData] from disk.
  ///
  /// Returns a fresh [ProfileData] if the file does not exist or fails to parse.
  Future<ProfileData> loadProfile() async {
    // A failed directory lookup/import must not masquerade as a fresh profile.
    final file = await _getFile(profileFileName);
    try {
      if (!await file.exists()) {
        return ProfileData();
      }
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return ProfileData.fromJson(json);
    } catch (_) {
      return ProfileData();
    }
  }

  /// Saves the persistent [ProfileData] to disk.
  Future<void> saveProfile(ProfileData profile) async {
    final file = await _getFile(profileFileName);
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(profile.toJson()));
  }

  /// Loads the transient [VoyageSaveData] from disk, if one exists.
  ///
  /// Returns `null` if no active voyage is saved or if parsing fails.
  Future<VoyageSaveData?> loadVoyage() async {
    final file = await _getFile(voyageFileName);
    try {
      if (!await file.exists()) {
        return null;
      }
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return VoyageSaveData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Saves the transient [VoyageSaveData] snapshot to disk.
  Future<void> saveVoyage(VoyageSaveData voyage) async {
    final file = await _getFile(voyageFileName);
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(voyage.toJson()));
  }

  /// Deletes the transient voyage save file to prevent save-scumming.
  Future<bool> clearVoyage() async {
    try {
      final file = await _getFile(voyageFileName);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Returns `true` if an active mid-voyage save snapshot exists on disk.
  Future<bool> hasActiveVoyage() async {
    try {
      final file = await _getFile(voyageFileName);
      return await file.exists();
    } catch (_) {
      return false;
    }
  }
}
