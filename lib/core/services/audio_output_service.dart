import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum OutputDeviceType {
  speaker,
  wiredHeadphones,
  bluetooth,
  unknown,
}

class OutputDevice {
  final String id;
  final String name;
  final OutputDeviceType type;
  final bool isConnected;

  const OutputDevice({
    required this.id,
    required this.name,
    required this.type,
    this.isConnected = true,
  });

  static OutputDevice speaker() => const OutputDevice(
        id: 'speaker',
        name: 'Speaker',
        type: OutputDeviceType.speaker,
      );

  static OutputDevice wiredHeadphones() => const OutputDevice(
        id: 'wired_headphones',
        name: 'Wired Headphones',
        type: OutputDeviceType.wiredHeadphones,
      );

  static OutputDevice bluetooth() => const OutputDevice(
        id: 'bluetooth',
        name: 'Bluetooth',
        type: OutputDeviceType.bluetooth,
      );
}

class AudioOutputService {
  static final AudioOutputService _instance = AudioOutputService._internal();
  factory AudioOutputService() => _instance;
  AudioOutputService._internal();

  static const MethodChannel _channel = MethodChannel('com.musiq.audio/output');

  final _currentDeviceController = StreamController<OutputDevice>.broadcast();
  final _availableDevicesController = StreamController<List<OutputDevice>>.broadcast();

  OutputDevice _currentDevice = OutputDevice.speaker();

  Stream<OutputDevice> get currentDeviceStream => _currentDeviceController.stream;
  Stream<List<OutputDevice>> get availableDevicesStream => _availableDevicesController.stream;
  OutputDevice get currentDevice => _currentDevice;

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    if (!Platform.isAndroid) return;

    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      await _refreshCurrentDevice();
      await _refreshAvailableDevices();
      _isInitialized = true;
    } catch (e) {
      // Audio output service not available
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDeviceChanged':
        final deviceId = call.arguments as String?;
        if (deviceId != null) {
          _currentDevice = _getDeviceFromId(deviceId);
          _currentDeviceController.add(_currentDevice);
        }
        await _refreshAvailableDevices();
        break;
    }
  }

  OutputDevice _getDeviceFromId(String id) {
    switch (id) {
      case 'speaker':
        return OutputDevice.speaker();
      case 'wired_headphones':
        return OutputDevice.wiredHeadphones();
      case 'bluetooth':
        return OutputDevice.bluetooth();
      default:
        return OutputDevice.speaker();
    }
  }

  Future<void> _refreshCurrentDevice() async {
    if (!Platform.isAndroid) return;
    try {
      final deviceId = await _channel.invokeMethod<String>('getCurrentDevice');
      if (deviceId != null) {
        _currentDevice = _getDeviceFromId(deviceId);
        _currentDeviceController.add(_currentDevice);
      }
    } catch (e) {
      // Default to speaker
    }
  }

  Future<void> _refreshAvailableDevices() async {
    final devices = await getOutputDevices();
    _availableDevicesController.add(devices);
  }

  Future<List<OutputDevice>> getOutputDevices() async {
    if (!Platform.isAndroid) {
      return [OutputDevice.speaker()];
    }

    try {
      final List<dynamic>? result = await _channel.invokeMethod('getAvailableDevices');
      if (result == null) {
        return [OutputDevice.speaker()];
      }

      final devices = <OutputDevice>[];
      for (final device in result) {
        if (device is Map) {
          devices.add(OutputDevice(
            id: device['id'] as String? ?? 'unknown',
            name: device['name'] as String? ?? 'Unknown',
            type: _parseDeviceType(device['type'] as String?),
            isConnected: device['connected'] as bool? ?? true,
          ));
        }
      }

      return devices.isEmpty ? [OutputDevice.speaker()] : devices;
    } catch (e) {
      return [OutputDevice.speaker()];
    }
  }

  OutputDeviceType _parseDeviceType(String? type) {
    switch (type) {
      case 'speaker':
        return OutputDeviceType.speaker;
      case 'wired_headphones':
        return OutputDeviceType.wiredHeadphones;
      case 'bluetooth':
        return OutputDeviceType.bluetooth;
      default:
        return OutputDeviceType.unknown;
    }
  }

  Future<bool> setOutputDevice(OutputDevice device) async {
    if (!Platform.isAndroid) return false;

    try {
      final result = await _channel.invokeMethod<bool>(
        'setOutputDevice',
        {'deviceId': device.id},
      );
      if (result == true) {
        _currentDevice = device;
        _currentDeviceController.add(_currentDevice);
      }
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  IconData getDeviceIcon(OutputDevice device) {
    switch (device.type) {
      case OutputDeviceType.speaker:
        return Icons.speaker_rounded;
      case OutputDeviceType.wiredHeadphones:
        return Icons.headphones_rounded;
      case OutputDeviceType.bluetooth:
        return Icons.bluetooth_rounded;
      case OutputDeviceType.unknown:
        return Icons.devices_rounded;
    }
  }

  void dispose() {
    _currentDeviceController.close();
    _availableDevicesController.close();
  }
}
