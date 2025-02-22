import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class RealTimeService {
  IOWebSocketChannel? _channel;
  Timer? _reconnectTimer;
  final Function(dynamic)? onData;
  final Function()? onConnected;
  final Function()? onDisconnected;
  final String socketUrl;
  bool _isConnected = false;
  static const _reconnectDelay = Duration(seconds: 5);
  
  RealTimeService({
    required this.socketUrl,
    this.onData,
    this.onConnected,
    this.onDisconnected,
  });
  
  bool get isConnected => _isConnected;
  
  Future<void> connect() async {
    if (_channel != null) return;
    
    try {
      final token = await StorageService.getToken();
      _channel = IOWebSocketChannel.connect(
        socketUrl,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      _channel!.stream.listen(
        (data) {
          _isConnected = true;
          onConnected?.call();
          try {
            final decoded = json.decode(data);
            onData?.call(decoded);
          } catch (e) {
            debugPrint('Error decoding WebSocket data: $e');
            onData?.call(data);
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _handleDisconnection();
        },
      );
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _handleDisconnection();
    }
  }
  
  void _handleDisconnection() {
    _isConnected = false;
    onDisconnected?.call();
    _channel?.sink.close();
    _channel = null;
    
    // Schedule reconnection
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, connect);
  }
  
  void send(dynamic message) {
    if (!_isConnected) return;
    
    try {
      final data = message is String ? message : json.encode(message);
      _channel?.sink.add(data);
    } catch (e) {
      debugPrint('Error sending WebSocket message: $e');
    }
  }
  
  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _channel = null;
    _isConnected = false;
  }
}
