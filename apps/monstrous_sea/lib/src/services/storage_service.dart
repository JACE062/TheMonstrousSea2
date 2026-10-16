import 'dart:convert';
import 'dart:io';

import 'package:monstrous_core/monstrous_core.dart';
import 'package:path_provider/path_provider.dart';

/// Service managing persistent disk storage for player profile and transient voyage saves.
///
/// Implements dual-file anti-scumming architecture:
/// - `player_profile.json`: Persistent profile (meta-inventory, lineage history, nemesis, town progress).
/// - `voyage_save.json`: Transient mid-voyage save snapshot (strictly auto-deleted upon captain demise
///   or returning to port).
class StorageService {
  StorageService({this.baseDirectory});

  final Directory? baseDirectory;

  static const String profileFileName = 'player_profile.json';
  static const String voyageFileName = 'voyage_save.json';

  Future<Directory> _resolveDirectory() async {
    final dir = baseDirectory;
    if (dir != null) {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  Future<File> _getFile(String fileName) async {
    final dir = await _resolveDirectory();
    final separator = Platform.pathSeparator;
    return File('${dir.path}$separator$fileName');
  }

  /// Loads the persistent [ProfileData] from disk.
  ///
  /// Returns a fresh [ProfileData] if the file does not exist or fails to parse.
  Future<ProfileData> loadProfile() async {
    try {
      final file = await _getFile(profileFileName);
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
    try {
      final file = await _getFile(voyageFileName);
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
