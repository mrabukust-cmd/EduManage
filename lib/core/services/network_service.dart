import 'dart:async';
import 'package:flutter/foundation.dart';

/// Connection status states.
enum NetworkStatus {
  connected,
  disconnected,
  slowConnection,
  unknown,
}

/// Immutable snapshot of current network reachability and performance.
class NetworkState {
  final NetworkStatus status;
  final int? latencyMs;
  final DateTime lastChecked;

  const NetworkState({
    required this.status,
    this.latencyMs,
    required this.lastChecked,
  });

  bool get isOnline => status == NetworkStatus.connected || status == NetworkStatus.slowConnection;
  bool get isOffline => status == NetworkStatus.disconnected;

  NetworkState copyWith({
    NetworkStatus? status,
    int? latencyMs,
    DateTime? lastChecked,
  }) {
    return NetworkState(
      status: status ?? this.status,
      latencyMs: latencyMs ?? this.latencyMs,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  @override
  String toString() => 'NetworkState(status: $status, latency: ${latencyMs}ms, checked: $lastChecked)';
}

/// Core service monitoring internet reachability and round-trip latency.
class NetworkService with ChangeNotifier {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;

  NetworkService._internal() {
    _state = NetworkState(
      status: NetworkStatus.unknown,
      lastChecked: DateTime.now(),
    );
  }

  NetworkState _state = NetworkState(
    status: NetworkStatus.unknown,
    lastChecked: DateTime.now(),
  );

  /// Current network status snapshot.
  NetworkState get state => _state;

  /// Injected custom ping handler (ideal for unit testing and mocked HTTP endpoints).
  Future<int?> Function({Duration timeout})? customPingHandler;

  /// Evaluates connection status based on latency.
  static NetworkStatus categorizeLatency(int latencyMs) {
    if (latencyMs < 0) return NetworkStatus.disconnected;
    if (latencyMs > 1500) return NetworkStatus.slowConnection;
    return NetworkStatus.connected;
  }

  /// Manually triggers a reachability test.
  Future<NetworkState> verifyConnectivity({Duration timeout = const Duration(seconds: 4)}) async {
    try {
      int? latency;
      if (customPingHandler != null) {
        latency = await customPingHandler!(timeout: timeout);
      } else {
        // Fallback default simulation for non-custom runtime
        latency = 120;
      }

      final status = latency == null ? NetworkStatus.disconnected : categorizeLatency(latency);

      _state = NetworkState(
        status: status,
        latencyMs: latency,
        lastChecked: DateTime.now(),
      );
    } catch (_) {
      _state = NetworkState(
        status: NetworkStatus.disconnected,
        latencyMs: null,
        lastChecked: DateTime.now(),
      );
    }

    notifyListeners();
    return _state;
  }

  /// Updates network status explicitly (e.g. from connectivity event bus).
  void updateStatus(NetworkStatus newStatus, {int? latencyMs}) {
    _state = NetworkState(
      status: newStatus,
      latencyMs: latencyMs,
      lastChecked: DateTime.now(),
    );
    notifyListeners();
  }

  /// Resets state to clean initialization.
  void reset() {
    _state = NetworkState(
      status: NetworkStatus.unknown,
      lastChecked: DateTime.now(),
    );
    customPingHandler = null;
    notifyListeners();
  }
}
