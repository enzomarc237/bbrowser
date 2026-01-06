import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../database/hive_helper.dart';
import '../database/database_config.dart';
import '../entities/tab.dart';
import '../repositories/tab_repository.dart';

/// Service for managing browser sessions and tab persistence
class SessionManager {
  final TabRepository _tabRepository;
  final HiveHelper _hiveHelper;
  final _uuid = const Uuid();
  
  String? _currentSessionId;
  Timer? _autoSaveTimer;
  
  static const String _currentSessionKey = 'current_session_id';
  static const String _sessionDataPrefix = 'session_';
  static const Duration _autoSaveInterval = Duration(seconds: 30);

  SessionManager({
    TabRepository? tabRepository,
    HiveHelper? hiveHelper,
  }) : _tabRepository = tabRepository ?? TabRepository(),
       _hiveHelper = hiveHelper ?? HiveHelper.instance;

  /// Initialize session manager
  Future<void> initialize() async {
    await _hiveHelper.initialize();
    await _loadCurrentSession();
    _startAutoSave();
  }

  /// Get current session ID
  String? get currentSessionId => _currentSessionId;

  /// Create a new session
  Future<String> createSession({String? name}) async {
    try {
      final sessionId = _uuid.v4();
      final sessionName = name ?? 'Session ${DateTime.now().toIso8601String()}';
      
      final session = TabSession.create(
        id: sessionId,
        name: sessionName,
        isActive: true,
      );
      
      // Save session metadata
      await _saveSessionMetadata(session);
      
      // Set as current session
      await _setCurrentSession(sessionId);
      
      return sessionId;
    } catch (e) {
      throw SessionManagerException('Failed to create session: $e');
    }
  }

  /// Load existing session or create new one
  Future<String> loadOrCreateSession() async {
    try {
      if (_currentSessionId != null) {
        // Check if current session has tabs
        final tabs = await _tabRepository.getBySessionId(_currentSessionId!);
        if (tabs.isNotEmpty) {
          return _currentSessionId!;
        }
      }
      
      // Create new session if none exists or current is empty
      return await createSession(name: 'Default Session');
    } catch (e) {
      throw SessionManagerException('Failed to load or create session: $e');
    }
  }

  /// Switch to a different session
  Future<void> switchToSession(String sessionId) async {
    try {
      await _setCurrentSession(sessionId);
    } catch (e) {
      throw SessionManagerException('Failed to switch to session: $e');
    }
  }

  /// Get all available sessions
  Future<List<TabSession>> getAllSessions() async {
    try {
      final sessionIds = await _tabRepository.getSessionIds();
      final sessions = <TabSession>[];
      
      for (final sessionId in sessionIds) {
        final session = await getSession(sessionId);
        if (session != null) {
          sessions.add(session);
        }
      }
      
      return sessions;
    } catch (e) {
      throw SessionManagerException('Failed to get all sessions: $e');
    }
  }

  /// Get session by ID
  Future<TabSession?> getSession(String sessionId) async {
    try {
      final tabs = await _tabRepository.getBySessionId(sessionId);
      final metadata = await _getSessionMetadata(sessionId);
      
      if (metadata != null) {
        return metadata.copyWith(tabs: tabs);
      }
      
      // Create metadata if it doesn't exist but tabs do
      if (tabs.isNotEmpty) {
        final session = TabSession.create(
          id: sessionId,
          name: 'Session $sessionId',
          isActive: sessionId == _currentSessionId,
        );
        await _saveSessionMetadata(session);
        return session.copyWith(tabs: tabs);
      }
      
      return null;
    } catch (e) {
      throw SessionManagerException('Failed to get session: $e');
    }
  }

  /// Get current session
  Future<TabSession?> getCurrentSession() async {
    if (_currentSessionId == null) return null;
    return await getSession(_currentSessionId!);
  }

  /// Save current session state
  Future<void> saveCurrentSession() async {
    try {
      if (_currentSessionId == null) return;
      
      final session = await getCurrentSession();
      if (session != null) {
        await _saveSessionData(session);
      }
    } catch (e) {
      throw SessionManagerException('Failed to save current session: $e');
    }
  }

  /// Restore session from saved data
  Future<TabSession?> restoreSession(String sessionId) async {
    try {
      final sessionData = await _getSessionData(sessionId);
      if (sessionData != null) {
        // Restore tabs to database
        final tabs = sessionData.tabs;
        if (tabs.isNotEmpty) {
          await _tabRepository.createBatch(tabs);
        }
        
        return sessionData;
      }
      
      return null;
    } catch (e) {
      throw SessionManagerException('Failed to restore session: $e');
    }
  }

  /// Delete session
  Future<void> deleteSession(String sessionId) async {
    try {
      // Don't delete current session
      if (sessionId == _currentSessionId) {
        throw SessionManagerException('Cannot delete current session');
      }
      
      // Delete tabs
      await _tabRepository.deleteBySessionId(sessionId);
      
      // Delete session metadata
      await _hiveHelper.deleteSessionData('${_sessionDataPrefix}metadata_$sessionId');
      await _hiveHelper.deleteSessionData('${_sessionDataPrefix}data_$sessionId');
    } catch (e) {
      throw SessionManagerException('Failed to delete session: $e');
    }
  }

  /// Duplicate session
  Future<String> duplicateSession(String sessionId, {String? newName}) async {
    try {
      final originalSession = await getSession(sessionId);
      if (originalSession == null) {
        throw SessionManagerException('Session not found');
      }
      
      final newSessionId = _uuid.v4();
      final duplicatedName = newName ?? '${originalSession.name} (Copy)';
      
      // Create new session
      final newSession = TabSession.create(
        id: newSessionId,
        name: duplicatedName,
      );
      
      // Duplicate tabs
      final duplicatedTabs = originalSession.tabs.map((tab) => 
        tab.copyWith(
          id: _uuid.v4(),
          sessionId: newSessionId,
          isActive: false, // Don't activate duplicated tabs
        )
      ).toList();
      
      // Save duplicated tabs
      if (duplicatedTabs.isNotEmpty) {
        await _tabRepository.createBatch(duplicatedTabs);
      }
      
      // Save session metadata
      await _saveSessionMetadata(newSession);
      
      return newSessionId;
    } catch (e) {
      throw SessionManagerException('Failed to duplicate session: $e');
    }
  }

  /// Rename session
  Future<void> renameSession(String sessionId, String newName) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) {
        throw SessionManagerException('Session not found');
      }
      
      final renamedSession = session.copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );
      
      await _saveSessionMetadata(renamedSession);
    } catch (e) {
      throw SessionManagerException('Failed to rename session: $e');
    }
  }

  /// Export session to JSON
  Future<String> exportSession(String sessionId) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) {
        throw SessionManagerException('Session not found');
      }
      
      return jsonEncode(session.toJson());
    } catch (e) {
      throw SessionManagerException('Failed to export session: $e');
    }
  }

  /// Import session from JSON
  Future<String> importSession(String jsonString, {String? name}) async {
    try {
      final sessionData = jsonDecode(jsonString) as Map<String, dynamic>;
      final session = TabSession.fromJson(sessionData);
      
      final newSessionId = _uuid.v4();
      final importedSession = session.copyWith(
        id: newSessionId,
        name: name ?? '${session.name} (Imported)',
        isActive: false,
      );
      
      // Import tabs with new session ID
      final importedTabs = session.tabs.map((tab) => 
        tab.copyWith(
          id: _uuid.v4(),
          sessionId: newSessionId,
          isActive: false,
        )
      ).toList();
      
      // Save imported tabs
      if (importedTabs.isNotEmpty) {
        await _tabRepository.createBatch(importedTabs);
      }
      
      // Save session metadata
      await _saveSessionMetadata(importedSession);
      
      return newSessionId;
    } catch (e) {
      throw SessionManagerException('Failed to import session: $e');
    }
  }

  /// Clean up old sessions
  Future<int> cleanupOldSessions({int retentionDays = 30}) async {
    try {
      final sessions = await getAllSessions();
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      int deletedCount = 0;
      
      for (final session in sessions) {
        if (session.id != _currentSessionId && 
            session.updatedAt.isBefore(cutoffDate)) {
          await deleteSession(session.id);
          deletedCount++;
        }
      }
      
      return deletedCount;
    } catch (e) {
      throw SessionManagerException('Failed to cleanup old sessions: $e');
    }
  }

  /// Get session statistics
  Future<Map<String, dynamic>> getSessionStatistics() async {
    try {
      final sessions = await getAllSessions();
      final totalTabs = sessions.fold<int>(0, (sum, session) => sum + session.tabs.length);
      final activeSessions = sessions.where((s) => s.isActive).length;
      
      return {
        'total_sessions': sessions.length,
        'active_sessions': activeSessions,
        'total_tabs': totalTabs,
        'average_tabs_per_session': sessions.isNotEmpty ? totalTabs / sessions.length : 0.0,
        'current_session_id': _currentSessionId,
      };
    } catch (e) {
      throw SessionManagerException('Failed to get session statistics: $e');
    }
  }

  /// Dispose session manager
  Future<void> dispose() async {
    _autoSaveTimer?.cancel();
    await saveCurrentSession();
  }

  /// Load current session from storage
  Future<void> _loadCurrentSession() async {
    try {
      _currentSessionId = await _hiveHelper.getSessionData<String>(_currentSessionKey);
    } catch (e) {
      // Ignore errors, will create new session if needed
    }
  }

  /// Set current session
  Future<void> _setCurrentSession(String sessionId) async {
    try {
      _currentSessionId = sessionId;
      await _hiveHelper.putSessionData(_currentSessionKey, sessionId);
      
      // Update session metadata to mark as active
      final session = await getSession(sessionId);
      if (session != null) {
        final activeSession = session.copyWith(
          isActive: true,
          updatedAt: DateTime.now(),
        );
        await _saveSessionMetadata(activeSession);
      }
    } catch (e) {
      throw SessionManagerException('Failed to set current session: $e');
    }
  }

  /// Save session metadata
  Future<void> _saveSessionMetadata(TabSession session) async {
    try {
      final metadataKey = '${_sessionDataPrefix}metadata_${session.id}';
      final metadata = {
        'id': session.id,
        'name': session.name,
        'isActive': session.isActive,
        'createdAt': session.createdAt.toIso8601String(),
        'updatedAt': session.updatedAt.toIso8601String(),
      };
      
      await _hiveHelper.putSessionData(metadataKey, jsonEncode(metadata));
    } catch (e) {
      throw SessionManagerException('Failed to save session metadata: $e');
    }
  }

  /// Get session metadata
  Future<TabSession?> _getSessionMetadata(String sessionId) async {
    try {
      final metadataKey = '${_sessionDataPrefix}metadata_$sessionId';
      final metadataJson = await _hiveHelper.getSessionData<String>(metadataKey);
      
      if (metadataJson != null) {
        final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
        return TabSession(
          id: metadata['id'] as String,
          name: metadata['name'] as String,
          isActive: metadata['isActive'] as bool? ?? false,
          createdAt: DateTime.parse(metadata['createdAt'] as String),
          updatedAt: DateTime.parse(metadata['updatedAt'] as String),
        );
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save session data
  Future<void> _saveSessionData(TabSession session) async {
    try {
      final dataKey = '${_sessionDataPrefix}data_${session.id}';
      await _hiveHelper.putSessionData(dataKey, jsonEncode(session.toJson()));
    } catch (e) {
      throw SessionManagerException('Failed to save session data: $e');
    }
  }

  /// Get session data
  Future<TabSession?> _getSessionData(String sessionId) async {
    try {
      final dataKey = '${_sessionDataPrefix}data_$sessionId';
      final sessionJson = await _hiveHelper.getSessionData<String>(dataKey);
      
      if (sessionJson != null) {
        final sessionData = jsonDecode(sessionJson) as Map<String, dynamic>;
        return TabSession.fromJson(sessionData);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Start auto-save timer
  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) {
      saveCurrentSession();
    });
  }
}

/// Exception thrown by session manager operations
class SessionManagerException implements Exception {
  final String message;
  
  const SessionManagerException(this.message);
  
  @override
  String toString() => 'SessionManagerException: $message';
}
