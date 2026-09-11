import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/services/network_service.dart';

void main() {
  late NetworkService networkService;

  setUp(() {
    networkService = NetworkService();
    networkService.reset();
  });

  group('NetworkService Tests', () {
    test('categorizeLatency classifies fast, slow, and offline correctly', () {
      expect(NetworkService.categorizeLatency(80), NetworkStatus.connected);
      expect(NetworkService.categorizeLatency(450), NetworkStatus.connected);
      expect(NetworkService.categorizeLatency(1800), NetworkStatus.slowConnection);
      expect(NetworkService.categorizeLatency(-1), NetworkStatus.disconnected);
    });

    test('verifyConnectivity updates state with custom handler ping result', () async {
      networkService.customPingHandler = ({Duration? timeout}) async {
        return 95; // Fast 95ms ping
      };

      final state = await networkService.verifyConnectivity();

      expect(state.status, NetworkStatus.connected);
      expect(state.latencyMs, 95);
      expect(state.isOnline, isTrue);
      expect(state.isOffline, isFalse);
    });

    test('verifyConnectivity identifies offline when custom handler returns null', () async {
      networkService.customPingHandler = ({Duration? timeout}) async {
        return null; // unreachable host
      };

      final state = await networkService.verifyConnectivity();

      expect(state.status, NetworkStatus.disconnected);
      expect(state.latencyMs, isNull);
      expect(state.isOnline, isFalse);
      expect(state.isOffline, isTrue);
    });

    test('verifyConnectivity handles thrown exceptions gracefully', () async {
      networkService.customPingHandler = ({Duration? timeout}) async {
        throw Exception('SocketException: Network unreachable');
      };

      final state = await networkService.verifyConnectivity();

      expect(state.status, NetworkStatus.disconnected);
      expect(state.latencyMs, isNull);
    });

    test('notifies listeners when status changes', () {
      var notificationCount = 0;
      networkService.addListener(() {
        notificationCount++;
      });

      networkService.updateStatus(NetworkStatus.disconnected);
      expect(notificationCount, 1);
      expect(networkService.state.isOffline, isTrue);

      networkService.updateStatus(NetworkStatus.connected, latencyMs: 40);
      expect(notificationCount, 2);
      expect(networkService.state.isOnline, isTrue);
      expect(networkService.state.latencyMs, 40);
    });
  });
}
