import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SecurityApp());
}

class AlertEvent {
  AlertEvent({
    required this.id,
    required this.time,
    required this.payload,
    required this.lighting,
    this.acknowledged = false,
    this.test = false,
  });

  final String id;
  final DateTime time;
  final String payload;
  final String lighting;
  bool acknowledged;
  final bool test;

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        'payload': payload,
        'lighting': lighting,
        'acknowledged': acknowledged,
        'test': test,
      };

  factory AlertEvent.fromJson(Map<String, dynamic> j) => AlertEvent(
        id: (j['id'] ?? '').toString(),
        time: DateTime.tryParse((j['time'] ?? '').toString()) ?? DateTime.now(),
        payload: (j['payload'] ?? '').toString(),
        lighting: (j['lighting'] ?? 'UNKNOWN').toString(),
        acknowledged: j['acknowledged'] == true,
        test: j['test'] == true,
      );
}

class SecurityController extends ChangeNotifier {
  static const MethodChannel _native = MethodChannel('esp32_secure/native');

  SharedPreferences? _prefs;
  MqttServerClient? _client;
  StreamSubscription? _mqttSubscription;
  Timer? _reconnectTimer;
  bool _connecting = false;

  String brokerHost = 'broker.emqx.io';
  int brokerPort = 1883;
  String topic = 'home/security/camera/capture';
  String cameraUrl = 'http://192.168.137.69/latest.jpg';
  String siteName = 'Home Security Prototype';
  bool notificationsEnabled = true;

  String mqttStatus = 'Offline';
  String statusDetail = 'Not connected';
  int imageVersion = DateTime.now().millisecondsSinceEpoch;
  final List<AlertEvent> alerts = [];

  AlertEvent? get latestAlert => alerts.isEmpty ? null : alerts.first;
  int get unreadCount => alerts.where((e) => !e.acknowledged).length;

  String get cacheBustedCameraUrl {
    final sep = cameraUrl.contains('?') ? '&' : '?';
    return cameraUrl + sep + 't=' + imageVersion.toString();
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    brokerHost = _prefs?.getString('brokerHost') ?? brokerHost;
    brokerPort = _prefs?.getInt('brokerPort') ?? brokerPort;
    topic = _prefs?.getString('topic') ?? topic;
    cameraUrl = _prefs?.getString('cameraUrl') ?? cameraUrl;
    siteName = _prefs?.getString('siteName') ?? siteName;
    notificationsEnabled = _prefs?.getBool('notificationsEnabled') ?? true;

    final raw = _prefs?.getString('alerts');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        alerts
          ..clear()
          ..addAll(list
              .whereType<Map<String, dynamic>>()
              .map(AlertEvent.fromJson));
      } catch (_) {
        // Ignore corrupted local history.
      }
    }
    notifyListeners();
    await connect();
  }

  Future<void> connect() async {
    if (_connecting) return;
    _connecting = true;
    _reconnectTimer?.cancel();

    await _mqttSubscription?.cancel();
    try {
      _client?.disconnect();
    } catch (_) {}

    mqttStatus = 'Connecting';
    statusDetail = 'Connecting to ' + brokerHost + ':' + brokerPort.toString();
    notifyListeners();

    final clientId = 'esp32secure_' +
        DateTime.now().millisecondsSinceEpoch.toRadixString(16) +
        Random().nextInt(9999).toString();

    final client = MqttServerClient.withPort(brokerHost, clientId, brokerPort);
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = () {
      mqttStatus = 'Connected';
      statusDetail = 'Subscribed to ' + topic;
      notifyListeners();
    };
    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    try {
      await client.connect();
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        _client = client;
        client.subscribe(topic, MqttQos.atLeastOnce);
        _mqttSubscription = client.updates?.listen((messages) {
          if (messages.isEmpty) return;
          final message = messages.first.payload as MqttPublishMessage;
          final payload =
              MqttPublishPayload.bytesToStringAsString(message.payload.message);
          _handlePayload(payload);
        });
        mqttStatus = 'Connected';
        statusDetail = 'Subscribed to ' + topic;
      } else {
        mqttStatus = 'Offline';
        statusDetail = 'Broker rejected connection';
        client.disconnect();
        _scheduleReconnect();
      }
    } catch (e) {
      mqttStatus = 'Offline';
      statusDetail = 'Connection failed: ' + e.toString();
      try {
        client.disconnect();
      } catch (_) {}
      _scheduleReconnect();
    } finally {
      _connecting = false;
      notifyListeners();
    }
  }

  void _onDisconnected() {
    mqttStatus = 'Offline';
    statusDetail = 'MQTT disconnected';
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), connect);
  }

  void _handlePayload(String raw) {
    final payload = raw
        .replaceAll(RegExp(r'[\x00-\x08\x0B-\x1F\x7F]'), '')
        .trim();
    final upper = payload.toUpperCase();
    String lighting = 'UNKNOWN';
    if (upper == 'CAPTURE') {
      lighting = 'BRIGHT';
    } else if (upper == 'CAPTURE_FLASH') {
      lighting = 'DARK';
    }

    final event = AlertEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      time: DateTime.now(),
      payload: payload.isEmpty ? '(empty payload)' : payload.substring(0, min(payload.length, 300)),
      lighting: lighting,
    );

    alerts.insert(0, event);
    if (alerts.length > 100) alerts.removeRange(100, alerts.length);
    _saveAlerts();
    imageVersion = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();

    if (notificationsEnabled) {
      final environment =
          lighting == 'DARK' ? 'Dark / flash capture' : lighting == 'BRIGHT' ? 'Bright / normal capture' : 'Security event';
      _showNotification('Security Alert – Motion detected', siteName + ' • ' + environment);
    }

    Timer(const Duration(seconds: 2), () {
      imageVersion = DateTime.now().millisecondsSinceEpoch;
      notifyListeners();
    });
  }

  Future<void> _showNotification(String title, String body) async {
    try {
      await _native.invokeMethod('showNotification', {
        'title': title,
        'body': body,
      });
    } catch (_) {}
  }

  Future<void> requestNotifications() async {
    try {
      await _native.invokeMethod('requestNotifications');
      notificationsEnabled = true;
      await _prefs?.setBool('notificationsEnabled', true);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> openCameraExternally() async {
    try {
      await _native.invokeMethod('openUrl', {'url': cameraUrl});
    } catch (_) {}
  }

  void refreshImage() {
    imageVersion = DateTime.now().millisecondsSinceEpoch;
    notifyListeners();
  }

  void testAlert() {
    final event = AlertEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      time: DateTime.now(),
      payload: 'TEST_ALERT',
      lighting: 'TEST',
      test: true,
    );
    alerts.insert(0, event);
    _saveAlerts();
    notifyListeners();
    if (notificationsEnabled) {
      _showNotification('ESP32 Secure Test Alert', siteName + ' • Test notification');
    }
  }

  void acknowledge(String id) {
    final event = alerts.where((e) => e.id == id).cast<AlertEvent?>().firstOrNull;
    if (event != null) event.acknowledged = true;
    _saveAlerts();
    notifyListeners();
  }

  void acknowledgeAll() {
    for (final event in alerts) {
      event.acknowledged = true;
    }
    _saveAlerts();
    notifyListeners();
  }

  void clearAlerts() {
    alerts.clear();
    _saveAlerts();
    notifyListeners();
  }

  Future<void> saveSettings({
    required String newBrokerHost,
    required int newBrokerPort,
    required String newTopic,
    required String newCameraUrl,
    required String newSiteName,
    required bool newNotificationsEnabled,
  }) async {
    brokerHost = newBrokerHost.trim().isEmpty ? 'broker.emqx.io' : newBrokerHost.trim();
    brokerPort = newBrokerPort <= 0 ? 1883 : newBrokerPort;
    topic = newTopic.trim().isEmpty ? 'home/security/camera/capture' : newTopic.trim();
    cameraUrl = newCameraUrl.trim().isEmpty ? 'http://192.168.137.69/latest.jpg' : newCameraUrl.trim();
    siteName = newSiteName.trim().isEmpty ? 'Home Security Prototype' : newSiteName.trim();
    notificationsEnabled = newNotificationsEnabled;

    await _prefs?.setString('brokerHost', brokerHost);
    await _prefs?.setInt('brokerPort', brokerPort);
    await _prefs?.setString('topic', topic);
    await _prefs?.setString('cameraUrl', cameraUrl);
    await _prefs?.setString('siteName', siteName);
    await _prefs?.setBool('notificationsEnabled', notificationsEnabled);
    notifyListeners();
    await connect();
  }

  Future<void> resetSettings() async {
    await saveSettings(
      newBrokerHost: 'broker.emqx.io',
      newBrokerPort: 1883,
      newTopic: 'home/security/camera/capture',
      newCameraUrl: 'http://192.168.137.69/latest.jpg',
      newSiteName: 'Home Security Prototype',
      newNotificationsEnabled: true,
    );
  }

  Future<void> _saveAlerts() async {
    final encoded = jsonEncode(alerts.map((e) => e.toJson()).toList());
    await _prefs?.setString('alerts', encoded);
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _mqttSubscription?.cancel();
    try {
      _client?.disconnect();
    } catch (_) {}
    super.dispose();
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}

class SecurityApp extends StatefulWidget {
  const SecurityApp({super.key});

  @override
  State<SecurityApp> createState() => _SecurityAppState();
}

class _SecurityAppState extends State<SecurityApp> {
  late final SecurityController controller;

  @override
  void initState() {
    super.initState();
    controller = SecurityController();
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF36A3FF),
      brightness: Brightness.dark,
      surface: const Color(0xFF101722),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ESP32 Secure',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B111A),
        cardTheme: const CardThemeData(
          color: Color(0xFF121C29),
          margin: EdgeInsets.zero,
        ),
      ),
      home: RootShell(controller: controller),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.controller});
  final SecurityController controller;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final pages = [
          HomePage(controller: widget.controller),
          AlertsPage(controller: widget.controller),
          CameraPage(controller: widget.controller),
          SettingsPage(controller: widget.controller),
          AboutPage(controller: widget.controller),
        ];
        return Scaffold(
          appBar: AppBar(
            title: Text(index == 0
                ? 'ESP32 Secure'
                : ['Home', 'Alerts', 'Camera', 'Settings', 'About'][index]),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(child: StatusPill(status: widget.controller.mqttStatus)),
              ),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(index: index, children: pages),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: [
              const NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'Home'),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: widget.controller.unreadCount > 0,
                  label: Text(widget.controller.unreadCount.toString()),
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: const Icon(Icons.notifications),
                label: 'Alerts',
              ),
              const NavigationDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt), label: 'Camera'),
              const NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
              const NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: 'About'),
            ],
          ),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});
  final SecurityController controller;

  @override
  Widget build(BuildContext context) {
    final last = controller.latestAlert;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'LOW-COST SMART SECURITY MONITORING SYSTEM',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.blue.shade200,
                letterSpacing: 1.4,
              ),
        ),
        const SizedBox(height: 6),
        Text(controller.siteName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                icon: Icons.wifi_tethering,
                label: 'MQTT',
                value: controller.mqttStatus,
                good: controller.mqttStatus == 'Connected',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                icon: Icons.camera_alt,
                label: 'Camera',
                value: 'Configured',
                good: controller.cameraUrl.isNotEmpty,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  controller.mqttStatus == 'Connected' ? Icons.shield : Icons.shield_outlined,
                  size: 38,
                  color: controller.mqttStatus == 'Connected' ? Colors.greenAccent : Colors.orangeAccent,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.mqttStatus == 'Connected' ? 'MONITORING ACTIVE' : 'WAITING FOR CONNECTION',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(controller.statusDetail, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Latest security event', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (last == null)
          const EmptyCard(text: 'No security events received yet.')
        else
          AlertCard(event: last, compact: true, onAcknowledge: () => controller.acknowledge(last.id)),
        const SizedBox(height: 12),
        Text('Latest ESP32-CAM image', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        CameraCard(controller: controller, height: 210),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: controller.testAlert,
                icon: const Icon(Icons.notification_add),
                label: const Text('Test Alert'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.refreshImage,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Image'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: controller.requestNotifications,
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Enable Phone Notifications'),
        ),
        const SizedBox(height: 10),
        const InfoBox(
          icon: Icons.info_outline,
          text: 'The app receives live MQTT alerts while it is running. For guaranteed alerts when the app is fully closed, add a push-notification backend in the commercial version.',
        ),
      ],
    );
  }
}

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key, required this.controller});
  final SecurityController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (controller.alerts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(controller.alerts.length.toString() + ' events'),
                const Spacer(),
                TextButton(onPressed: controller.acknowledgeAll, child: const Text('Acknowledge all')),
                TextButton(
                  onPressed: () async {
                    final yes = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Clear alert history?'),
                        content: const Text('This removes the local history stored on this phone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
                        ],
                      ),
                    );
                    if (yes == true) controller.clearAlerts();
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        Expanded(
          child: controller.alerts.isEmpty
              ? const Center(child: Text('No alerts yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final event = controller.alerts[i];
                    return AlertCard(
                      event: event,
                      onAcknowledge: () => controller.acknowledge(event.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class CameraPage extends StatelessWidget {
  const CameraPage({super.key, required this.controller});
  final SecurityController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CameraCard(controller: controller, height: 330),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: controller.refreshImage,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.openCameraExternally,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open in Browser'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InfoBox(
          icon: Icons.link,
          text: 'Camera URL: ' + controller.cameraUrl,
        ),
        const SizedBox(height: 8),
        const InfoBox(
          icon: Icons.privacy_tip_outlined,
          text: 'Camera images may contain personal information. Keep access restricted and do not expose the camera publicly without authentication.',
        ),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});
  final SecurityController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController host;
  late final TextEditingController port;
  late final TextEditingController topic;
  late final TextEditingController camera;
  late final TextEditingController site;
  late bool notifications;

  @override
  void initState() {
    super.initState();
    host = TextEditingController(text: widget.controller.brokerHost);
    port = TextEditingController(text: widget.controller.brokerPort.toString());
    topic = TextEditingController(text: widget.controller.topic);
    camera = TextEditingController(text: widget.controller.cameraUrl);
    site = TextEditingController(text: widget.controller.siteName);
    notifications = widget.controller.notificationsEnabled;
  }

  @override
  void dispose() {
    host.dispose();
    port.dispose();
    topic.dispose();
    camera.dispose();
    site.dispose();
    super.dispose();
  }

  Future<void> save() async {
    await widget.controller.saveSettings(
      newBrokerHost: host.text,
      newBrokerPort: int.tryParse(port.text) ?? 1883,
      newTopic: topic.text,
      newCameraUrl: camera.text,
      newSiteName: site.text,
      newNotificationsEnabled: notifications,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved. Reconnecting MQTT…')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const InfoBox(
          icon: Icons.science_outlined,
          text: 'Prototype defaults match your current ESP32 setup. No Wi-Fi password is stored in this app.',
        ),
        const SizedBox(height: 12),
        Field(controller: host, label: 'MQTT broker host', hint: 'broker.emqx.io'),
        Field(controller: port, label: 'MQTT port', hint: '1883', keyboardType: TextInputType.number),
        Field(controller: topic, label: 'MQTT alert/camera topic', hint: 'home/security/camera/capture'),
        Field(controller: camera, label: 'ESP32-CAM latest image URL', hint: 'http://192.168.137.69/latest.jpg'),
        Field(controller: site, label: 'Site / device name', hint: 'Home Security Prototype'),
        SwitchListTile(
          value: notifications,
          onChanged: (v) => setState(() => notifications = v),
          title: const Text('Phone notifications'),
          subtitle: const Text('Show a system alert when MQTT motion events arrive.'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: save, icon: const Icon(Icons.save), label: const Text('Save & Reconnect')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: widget.controller.connect, icon: const Icon(Icons.sync), label: const Text('Reconnect MQTT')),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await widget.controller.resetSettings();
            if (!mounted) return;
            setState(() {
              host.text = widget.controller.brokerHost;
              port.text = widget.controller.brokerPort.toString();
              topic.text = widget.controller.topic;
              camera.text = widget.controller.cameraUrl;
              site.text = widget.controller.siteName;
              notifications = widget.controller.notificationsEnabled;
            });
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset Defaults'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.controller.requestNotifications,
          icon: const Icon(Icons.notifications_active),
          label: const Text('Request Notification Permission'),
        ),
        const SizedBox(height: 16),
        const InfoBox(
          icon: Icons.security,
          text: 'The public EMQX broker and unauthenticated topic are suitable for a university prototype only. A production security product should use authenticated TLS/private MQTT infrastructure.',
        ),
      ],
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, required this.controller});
  final SecurityController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(Icons.shield_outlined, size: 68, color: Colors.lightBlueAccent),
        const SizedBox(height: 12),
        Text(
          'Low-Cost Smart Security Monitoring System Using ESP32',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        const ArchitectureStep(number: '01', icon: Icons.sensors, title: 'ESP32 Sensor Controller', text: 'PIR detects motion, LDR determines light level and the buzzer sounds for the local alarm.'),
        const ArchitectureStep(number: '02', icon: Icons.wifi_tethering, title: 'MQTT', text: 'The ESP32 publishes CAPTURE in bright conditions or CAPTURE_FLASH when it is dark.'),
        const ArchitectureStep(number: '03', icon: Icons.camera_alt, title: 'ESP32-CAM', text: 'The camera receives the MQTT command and updates the real JPEG at /latest.jpg.'),
        const ArchitectureStep(number: '04', icon: Icons.phone_android, title: 'Homeowner App', text: 'This Android app records the event, shows a phone notification and refreshes the latest camera image.'),
        const SizedBox(height: 8),
        const InfoBox(
          icon: Icons.gavel_outlined,
          text: 'For real deployment, protect camera images and personal information, use authenticated encrypted communications, and comply with applicable safety and privacy requirements.',
        ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final connected = status == 'Connected';
    final connecting = status == 'Connecting';
    final color = connected ? Colors.greenAccent : connecting ? Colors.orangeAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.icon, required this.label, required this.value, required this.good});
  final IconData icon;
  final String label;
  final String value;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: good ? Colors.greenAccent : Colors.orangeAccent),
            const SizedBox(height: 10),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.event, required this.onAcknowledge, this.compact = false});
  final AlertEvent event;
  final VoidCallback onAcknowledge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = event.lighting == 'DARK';
    final isBright = event.lighting == 'BRIGHT';
    final color = event.test ? Colors.blueAccent : Colors.redAccent;
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: event.acknowledged ? Colors.transparent : color.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(event.test ? Icons.science : Icons.warning_amber_rounded, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.test ? 'TEST ALERT' : 'SECURITY ALERT',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!event.acknowledged)
                  TextButton(onPressed: onAcknowledge, child: const Text('Acknowledge')),
              ],
            ),
            Text(
              event.test ? 'App notification test' : 'Motion / camera trigger received',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Tag(text: formatDateTime(event.time), icon: Icons.schedule),
                Tag(
                  text: isDark ? 'Dark • Flash' : isBright ? 'Bright • Normal' : event.lighting,
                  icon: isDark ? Icons.dark_mode : isBright ? Icons.light_mode : Icons.info_outline,
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 8),
              Text('Payload: ' + event.payload, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class CameraCard extends StatelessWidget {
  const CameraCard({super.key, required this.controller, required this.height});
  final SecurityController controller;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              controller.cacheBustedCameraUrl,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, error, __) => Container(
                color: const Color(0xFF172231),
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_off_outlined, size: 42, color: Colors.white54),
                    const SizedBox(height: 10),
                    const Text('Camera image not reachable', textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(
                      'Power the ESP32-CAM and make sure this phone can reach its current IP address.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: controller.openCameraExternally,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open Camera URL'),
                    ),
                  ],
                ),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.redAccent),
                    SizedBox(width: 5),
                    Text('LATEST JPEG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Field extends StatelessWidget {
  const Field({super.key, required this.controller, required this.label, required this.hint, this.keyboardType});
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder()),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  const Tag({super.key, required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ),
    );
  }
}

class InfoBox extends StatelessWidget {
  const InfoBox({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.lightBlueAccent),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class ArchitectureStep extends StatelessWidget {
  const ArchitectureStep({
    super.key,
    required this.number,
    required this.icon,
    required this.title,
    required this.text,
  });
  final String number;
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.12),
              child: Icon(icon, color: Colors.lightBlueAccent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(number + '  ' + title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(text, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return two(d.day) + '/' + two(d.month) + '/' + d.year.toString() + '  ' + two(d.hour) + ':' + two(d.minute) + ':' + two(d.second);
}
