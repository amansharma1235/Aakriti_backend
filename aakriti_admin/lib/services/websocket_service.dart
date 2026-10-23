import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

enum WsConnectionState { disconnected, connecting, connected }

class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  final ValueNotifier<WsConnectionState> connectionState =
      ValueNotifier<WsConnectionState>(WsConnectionState.disconnected);

  // Broadcast stream for incoming typed events
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  // Event callbacks for quick listeners
  final List<void Function(Map<String, dynamic> event)> _listeners = [];

  // Exponential backoff configuration
  int _retryAttempt = 0;
  static const int _baseDelaySeconds = 1;
  static const int _maxDelaySeconds = 30;
  bool _isDisposed = false;

  void addListener(void Function(Map<String, dynamic> event) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(Map<String, dynamic> event) listener) {
    _listeners.remove(listener);
  }

  /// Convert HTTP baseUrl (e.g. http://10.110.207.51:8001 or http://localhost:8000) to WebSocket URL
  Uri _getWsUri() {
    final httpUri = Uri.parse(ApiService.baseUrl);
    final wsScheme = httpUri.scheme == 'https' ? 'wss' : 'ws';
    return httpUri.replace(scheme: wsScheme, path: '/ws/admin');
  }

  /// Initialize and connect WebSocket
  Future<void> connect() async {
    if (_isDisposed) return;
    if (connectionState.value == WsConnectionState.connecting ||
        connectionState.value == WsConnectionState.connected) {
      return;
    }

    connectionState.value = WsConnectionState.connecting;
    _cancelHeartbeat();
    _cancelReconnect();

    final wsUri = _getWsUri();
    debugPrint('[WebSocket] Connecting to $wsUri...');

    try {
      _channel = WebSocketChannel.connect(wsUri);
      await _channel!.ready;

      connectionState.value = WsConnectionState.connected;
      _retryAttempt = 0;
      debugPrint('[WebSocket] Connected successfully!');

      // Start ping heartbeat
      _startHeartbeat();

      // Listen for incoming stream
      _subscription = _channel!.stream.listen(
        (data) {
          _handleIncomingMessage(data);
        },
        onError: (error) {
          debugPrint('[WebSocket] Stream error: $error');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('[WebSocket] Stream closed by server.');
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[WebSocket] Connection failed: $e');
      _handleDisconnect();
    }
  }

  void _handleIncomingMessage(dynamic rawData) {
    try {
      final decoded = jsonDecode(rawData.toString());
      if (decoded is Map<String, dynamic>) {
        final event = decoded['event'] ?? 'UNKNOWN';
        debugPrint('[WebSocket] Event received: $event');

        // Dispatch to stream & listeners
        _eventController.add(decoded);
        for (final listener in List.from(_listeners)) {
          try {
            listener(decoded);
          } catch (e) {
            debugPrint('[WebSocket] Listener error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[WebSocket] Message decode error: $e');
    }
  }

  void _handleDisconnect() {
    _cleanupChannel();
    if (_isDisposed) return;

    connectionState.value = WsConnectionState.disconnected;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _cancelReconnect();
    if (_isDisposed) return;

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, max 30s
    final delay = min(
      _baseDelaySeconds * pow(2, _retryAttempt).toInt(),
      _maxDelaySeconds,
    );
    _retryAttempt++;

    debugPrint('[WebSocket] Reconnecting in $delay seconds (attempt $_retryAttempt)...');
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      connect();
    });
  }

  void _startHeartbeat() {
    _cancelHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (connectionState.value == WsConnectionState.connected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'PING', 'timestamp': DateTime.now().toIso8601String()}));
        } catch (e) {
          debugPrint('[WebSocket] Heartbeat failed: $e');
          _handleDisconnect();
        }
      }
    });
  }

  void _cancelHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _cleanupChannel() {
    _cancelHeartbeat();
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  /// Manually trigger reconnect
  void reconnect() {
    _cleanupChannel();
    _retryAttempt = 0;
    connect();
  }

  /// Send message
  void send(Map<String, dynamic> data) {
    if (connectionState.value == WsConnectionState.connected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (e) {
        debugPrint('[WebSocket] Send failed: $e');
      }
    }
  }

  /// Disconnect manually
  void disconnect() {
    _cancelReconnect();
    _cleanupChannel();
    connectionState.value = WsConnectionState.disconnected;
  }

  void dispose() {
    _isDisposed = true;
    disconnect();
    _eventController.close();
  }
}
