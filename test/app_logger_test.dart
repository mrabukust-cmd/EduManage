import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/utils/app_logger.dart';

void main() {
  setUp(() {
    AppLogger.clearLogs();
    AppLogger.minLogLevel = LogLevel.debug;
    AppLogger.customPrinter = null;
  });

  group('AppLogger Unit Tests', () {
    test('logs debug, info, warning, error, and fatal messages', () {
      AppLogger.debug('Debug payload', tag: 'Auth');
      AppLogger.info('User logged in', tag: 'Auth');
      AppLogger.warning('High latency detected', tag: 'Network');
      AppLogger.error('Failed to sync fee records', tag: 'Fees', error: Exception('Timeout'));
      AppLogger.fatal('App crash simulation', tag: 'Crash');

      expect(AppLogger.recentLogs.length, 5);
      expect(AppLogger.recentLogs[0].level, LogLevel.debug);
      expect(AppLogger.recentLogs[1].level, LogLevel.info);
      expect(AppLogger.recentLogs[2].level, LogLevel.warning);
      expect(AppLogger.recentLogs[3].level, LogLevel.error);
      expect(AppLogger.recentLogs[4].level, LogLevel.wtf);

      expect(AppLogger.recentLogs[0].tag, 'Auth');
      expect(AppLogger.recentLogs[3].error.toString(), contains('Timeout'));
    });

    test('respects minLogLevel filtering', () {
      AppLogger.minLogLevel = LogLevel.warning;

      AppLogger.debug('Ignored debug');
      AppLogger.info('Ignored info');
      AppLogger.warning('Accepted warning');
      AppLogger.error('Accepted error');

      expect(AppLogger.recentLogs.length, 2);
      expect(AppLogger.recentLogs.first.level, LogLevel.warning);
      expect(AppLogger.recentLogs.last.level, LogLevel.error);
    });

    test('respects maxBufferSize and purges oldest logs', () {
      AppLogger.maxBufferSize = 3;

      AppLogger.info('Log 1');
      AppLogger.info('Log 2');
      AppLogger.info('Log 3');
      AppLogger.info('Log 4');

      expect(AppLogger.recentLogs.length, 3);
      expect(AppLogger.recentLogs[0].message, 'Log 2');
      expect(AppLogger.recentLogs[1].message, 'Log 3');
      expect(AppLogger.recentLogs[2].message, 'Log 4');
    });

    test('exportLogsAsString formats correctly', () {
      AppLogger.info('Starting service', tag: 'System');
      AppLogger.warning('Storage almost full', tag: 'Storage');

      final exported = AppLogger.exportLogsAsString();
      expect(exported, contains('[INFO] [System] Starting service'));
      expect(exported, contains('[WARN] [Storage] Storage almost full'));
    });

    test('invokes customPrinter hook when configured', () {
      final printed = <LogEntry>[];
      AppLogger.customPrinter = (entry) => printed.add(entry);

      AppLogger.info('Custom print message', tag: 'Hook');

      expect(printed.length, 1);
      expect(printed.first.message, 'Custom print message');
      expect(printed.first.tag, 'Hook');
    });
  });
}
