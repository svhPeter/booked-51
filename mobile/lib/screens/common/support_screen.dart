import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Help & Legal'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Support'),
              Tab(text: 'Privacy Policy'),
              Tab(text: 'Terms'),
              Tab(text: 'Disclaimer'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SupportTab(),
            _PrivacyTab(),
            _TermsTab(),
            _DisclaimerTab(),
          ],
        ),
      ),
    );
  }
}

class _SupportTab extends StatelessWidget {
  const _SupportTab();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.support_agent_rounded, size: 48, color: scheme.primary),
          const SizedBox(height: 16),
          Text('Need Help?', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Our support team is here to help you with any questions or issues.',
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 24),
          _ContactCard(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@docbook.pk',
            detail: 'We typically respond within 24 hours.',
          ),
          const SizedBox(height: 12),
          _ContactCard(
            icon: Icons.chat_outlined,
            title: 'WhatsApp',
            subtitle: 'Chat with us',
            detail: 'Available Mon–Sat, 9 AM – 6 PM PKT',
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.primarySurfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    'DocBook Beta',
                    style: TextStyle(fontWeight: FontWeight.w600, color: scheme.primary),
                  ),
                const SizedBox(height: 4),
                  Text(
                    'You are using an early beta version of DocBook. '
                    'We appreciate your feedback and patience as we improve the platform.',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.5),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String detail;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(fontSize: 13, color: scheme.primary)),
                Text(detail, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyTab extends StatelessWidget {
  const _PrivacyTab();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Privacy Policy', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Last updated: May 2026', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          const _LegalSection(
            title: 'Information We Collect',
            body: 'DocBook collects your name, email address, phone number, and city '
                'to provide appointment booking services. Doctor profiles include '
                'professional qualifications and clinic addresses.',
          ),
          const _LegalSection(
            title: 'How We Use Your Information',
            body: 'Your information is used solely to facilitate appointment requests '
                'between patients and doctors. We do not sell your data to third parties.',
          ),
          const _LegalSection(
            title: 'Data Security',
            body: 'We use industry-standard encryption and security measures to protect '
                'your personal information. Passwords are hashed and never stored in plain text.',
          ),
          const _LegalSection(
            title: 'Communication',
            body: 'We send transactional emails for OTP verification, appointment confirmations, '
                'and important account updates. You will not receive marketing emails without consent.',
          ),
          const _LegalSection(
            title: 'Contact',
            body: 'For privacy-related inquiries, contact us at support@docbook.pk.',
          ),
        ],
      ),
    );
  }
}

class _TermsTab extends StatelessWidget {
  const _TermsTab();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Terms of Service', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('Last updated: May 2026', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          const _LegalSection(
            title: 'Acceptance of Terms',
            body: 'By using DocBook, you agree to these Terms of Service. '
                'If you do not agree, please do not use the platform.',
          ),
          const _LegalSection(
            title: 'Service Description',
            body: 'DocBook is a free appointment request platform connecting patients '
                'with doctors in Pakistan. Patients request appointments; doctors '
                'confirm final timing. There is no platform fee for patients.',
          ),
          const _LegalSection(
            title: 'Payment',
            body: 'DocBook does not process payments. Consultation fees are paid '
                'directly to the doctor or clinic at the time of your visit.',
          ),
          const _LegalSection(
            title: 'Doctor Verification',
            body: 'Doctors listed on DocBook are admin-approved. However, DocBook '
                'does not guarantee medical qualifications beyond verification steps taken.',
          ),
          const _LegalSection(
            title: 'User Responsibilities',
            body: 'Users must provide accurate information. Misuse of the platform, '
                'including false reports or fraudulent accounts, may result in account suspension.',
          ),
          const _LegalSection(
            title: 'Limitation of Liability',
            body: 'DocBook is a booking platform and is not responsible for medical '
                'advice, treatment outcomes, or disputes between patients and doctors.',
          ),
        ],
      ),
    );
  }
}

class _DisclaimerTab extends StatelessWidget {
  const _DisclaimerTab();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Medical Disclaimer', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.errorSurfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.error.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(Icons.local_hospital_rounded, size: 40, color: scheme.error),
                const SizedBox(height: 12),
                Text(
                  'DocBook is NOT a medical emergency service.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: scheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'If you are experiencing a medical emergency, '
                  'please call emergency services or go to your nearest hospital immediately.',
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _LegalSection(
            title: 'Platform Role',
            body: 'DocBook is a booking/scheduling platform only. We facilitate '
                'appointment requests between patients and healthcare providers.',
          ),
          const _LegalSection(
            title: 'Medical Advice',
            body: 'DocBook does not provide medical advice, diagnosis, or treatment. '
                'All medical decisions are the responsibility of the attending doctor '
                'and the patient.',
          ),
          const _LegalSection(
            title: 'Doctor Responsibility',
            body: 'Doctors and clinics listed on DocBook are independently responsible '
                'for the quality of care, medical advice, and treatment they provide.',
          ),
          const _LegalSection(
            title: 'Emergency Services',
            body: 'For medical emergencies in Pakistan, contact:\n'
                '• Rescue: 1122\n'
                '• Ambulance: 115\n'
                '• Edhi Foundation: 0800-111-1122',
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String title;
  final String body;

  const _LegalSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant, height: 1.6),
          ),
        ],
      ),
    );
  }
}
