import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'fitness_integrations.dart';
import 'run_tracking_store.dart';
import 'training_store.dart';

class FitnessIntegrationsScreen extends StatefulWidget {
  const FitnessIntegrationsScreen({super.key});

  @override
  State<FitnessIntegrationsScreen> createState() =>
      _FitnessIntegrationsScreenState();
}

class _FitnessIntegrationsScreenState extends State<FitnessIntegrationsScreen> {
  bool _exporting = false;

  Future<void> _copyExport() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final workouts = await TrainingStore.loadWorkouts();
      final runs = await RunTrackingStore.load();
      final payload = FitnessActivityExporter.all(
        workouts: workouts,
        runs: runs,
      ).map((item) => item.toJson()).toList(growable: false);
      await Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(payload)),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${payload.length} activities copied as integration-ready JSON.')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Health & devices'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
        children: [
          const Text(
            'Integration-ready ecosystem',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'LeanIt has a common activity export model for strength and running. A provider is never shown as connected until its platform permissions or developer credentials are genuinely configured.',
            style: TextStyle(height: 1.45, color: Color(0xFF627D98)),
          ),
          const SizedBox(height: 18),
          ...FitnessIntegrationRegistry.providers.map(_providerCard),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _exporting ? null : _copyExport,
            icon: const Icon(Icons.data_object_rounded),
            label: Text(_exporting ? 'PREPARING…' : 'COPY ACTIVITY EXPORT JSON'),
          ),
          const SizedBox(height: 8),
          const Text(
            'This export is useful for testing connectors and does not send data to any third party by itself.',
            style: TextStyle(fontSize: 12, color: Color(0xFF829AB1)),
          ),
        ],
      ),
    );
  }

  Widget _providerCard(FitnessIntegrationDescriptor provider) {
    final status = switch (provider.status) {
      FitnessIntegrationStatus.connected => 'CONNECTED',
      FitnessIntegrationStatus.availableLocally => 'AVAILABLE',
      FitnessIntegrationStatus.requiresPlatformSetup => 'PLATFORM SETUP REQUIRED',
      FitnessIntegrationStatus.requiresDeveloperCredentials => 'CREDENTIALS REQUIRED',
      FitnessIntegrationStatus.unavailable => 'UNAVAILABLE',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.watch_rounded, color: Color(0xFF176B87)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    provider.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(label: Text(status, style: const TextStyle(fontSize: 10))),
              ],
            ),
            const SizedBox(height: 8),
            Text(provider.purpose),
            const SizedBox(height: 8),
            Text(
              provider.capabilities.join(' • '),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF176B87),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.setupNote,
              style: const TextStyle(fontSize: 12, color: Color(0xFF627D98)),
            ),
          ],
        ),
      ),
    );
  }
}
