import 'package:flutter/foundation.dart';

/// Severity levels for application logs.
enum LogLevel {
  debug,
  info,
  warning,
  error,
  wtf,
}

/// A structured log record containing metadata, timestamp, and payload.
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String get levelLabel {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.wtf:
        return 'FATAL';
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer('[$formattedTime] [$levelLabel] [$tag] $message');
    if (error != null) {
      buffer.write(' | Error: $error');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    return buffer.toString();
  }
}

/// Professional structured logger with in-memory buffering and configurable severity.
class AppLogger {
  AppLogger._();

  static const String defaultTag = 'EduManage';
  static LogLevel minLogLevel = kReleaseMode ? LogLevel.info : LogLevel.debug;
  static int maxBufferSize = 200;

  static final List<LogEntry> _buffer = [];
  static void Function(LogEntry entry)? customPrinter;

  /// Returns an unmodifiable view of in-memory logs.
  static List<LogEntry> get recentLogs => List.unmodifiable(_buffer);

  /// Clears in-memory log buffer.
  static void clearLogs() {
    _buffer.clear();
  }

  /// Exports buffer contents as newline-delimited text for diagnostics.
  static String exportLogsAsString() {
    return _buffer.map((e) => e.toString()).join('\n');
  }

  static void debug(String message, {String tag = defaultTag, Object? error}) {
    _log(LogLevel.debug, message, tag: tag, error: error);
  }

  static void info(String message, {String tag = defaultTag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  static void warning(String message, {String tag = defaultTag, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }

  static void error(
    String message, {
    String tag = defaultTag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void fatal(
    String message, {
    String tag = defaultTag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.wtf, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    required String tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minLogLevel.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    if (_buffer.length >= maxBufferSize) {
      _buffer.removeAt(0);
    }
    _buffer.add(entry);

    if (customPrinter != null) {
      customPrinter!(entry);
    } else {
      debugPrint(entry.toString());
    }
  }
}
