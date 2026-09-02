import 'package:flutter/material.dart';

import 'evidence_rule_engine.dart';

class EvidenceReviewScreen extends StatefulWidget {
  const EvidenceReviewScreen({super.key});

  @override
  State<EvidenceReviewScreen> createState() => _EvidenceReviewScreenState();
}

class _EvidenceReviewScreenState extends State<EvidenceReviewScreen> {
  EvidenceReviewStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final rules = EvidenceRuleRegistry.rules
        .where((rule) => _filter == null || rule.reviewStatus == _filter)
        .toList(growable: false);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Evidence & review'),
        backgroundColor: const Color(0xFFF7F9FC),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
        children: [
          const Text(
            'Programme rule registry',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'LeanIt separates evidence rules from AI wording. Only rules with Approved status can drive automatic training changes. Draft or retired rules remain visible for review but are blocked from automation.',
            style: TextStyle(height: 1.45, color: Color(0xFF627D98)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              ...EvidenceReviewStatus.values.map(
                (status) => ChoiceChip(
                  label: Text(status.name.toUpperCase()),
                  selected: _filter == status,
                  onSelected: (_) => setState(() => _filter = status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rules.map(_ruleCard),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Production approval is intentionally not editable by ordinary app users. A future authenticated coach/research admin role can write review decisions without exposing that authority to the public client.',
              style: TextStyle(height: 1.4, color: Color(0xFF6B4F00)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ruleCard(EvidenceRule rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          rule.canDriveAutomation
              ? Icons.verified_rounded
              : Icons.pending_actions_rounded,
          color: rule.canDriveAutomation
              ? const Color(0xFF0F6B4B)
              : const Color(0xFF9A6700),
        ),
        title: Text(
          rule.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${rule.reviewStatus.name.toUpperCase()} • ${rule.id}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _field('Goals', rule.goals.join(', ')),
          _field('Experience', rule.experienceLevels.join(', ')),
          _field('Movement role', rule.movementRole),
          _field('Weekly target', rule.weeklyTarget),
          _field('Sets', rule.sets),
          _field('Reps', rule.reps),
          _field('Rest', rule.rest),
          _field('Progression rule', rule.progressionRule),
          _field('Recovery rule', rule.recoveryRule),
          _field('Allowed substitutions', rule.allowedSubstitutions.join(', ')),
          _field('Environment', rule.environments.join(', ')),
          _field('Equipment', rule.equipment.join(', ')),
          _field('Sources', rule.sources.join(' • ')),
          if (rule.reviewerNote.isNotEmpty)
            _field('Review note', rule.reviewerNote),
        ],
      ),
    );
  }

  Widget _field(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Color(0xFF486581), height: 1.4),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),
              TextSpan(text: value.isEmpty ? '—' : value),
            ],
          ),
        ),
      ),
    );
  }
}
