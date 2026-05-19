import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/application_service.dart';
import '../../services/room_service.dart';
import '../../models/application_model.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});
  final _appService = ApplicationService();
  final _roomService = RoomService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.go('/rooms'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => auth.logout(),
                tooltip: 'Çıkış Yap',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: AppColors.mainGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2),
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 42),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.isAdmin ? 'Yurt Görevlisi' : 'Öğrenci',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileInfoCard(user: user, roomService: _roomService),
                  const SizedBox(height: 20),
                  const Text(
                    'Başvuru Geçmişim',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<ApplicationModel>>(
                    stream: _appService.getUserApplications(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final apps = snapshot.data ?? [];
                      if (apps.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 40,
                                    color: AppColors.textSecondary),
                                SizedBox(height: 8),
                                Text('Henüz başvurunuz bulunmuyor.',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        children:
                            apps.map((a) => _AppCard(app: a)).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => context.go('/rooms'),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.mainGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: Colors.white),
                          SizedBox(width: 8),
                          Text('Yeni Başvuru Yap',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final dynamic user;
  final RoomService roomService;
  const _ProfileInfoCard({required this.user, required this.roomService});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Öğrenci No',
            value: user.studentNo,
          ),
          const Divider(height: 20),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'E-posta',
            value: user.email,
          ),
          if (user.roomId != null) ...[
            const Divider(height: 20),
            FutureBuilder(
              future: roomService.getRoom(user.roomId!),
              builder: (context, snap) {
                final roomNo = snap.data?.number ?? '...';
                return _InfoRow(
                  icon: Icons.home_outlined,
                  label: 'Atanan Oda',
                  value: 'Oda $roomNo',
                  valueColor: AppColors.green,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _AppCard extends StatelessWidget {
  final ApplicationModel app;
  const _AppCard({required this.app});

  Color get _statusColor {
    switch (app.status) {
      case 'approved':
        return AppColors.green;
      case 'rejected':
        return AppColors.red;
      default:
        return AppColors.orange;
    }
  }

  String get _statusText {
    switch (app.status) {
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Beklemede';
    }
  }

  IconData get _statusIcon {
    switch (app.status) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon, color: _statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Oda ${app.roomNumber}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR')
                      .format(app.date),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              _statusText,
              style: TextStyle(
                color: _statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
