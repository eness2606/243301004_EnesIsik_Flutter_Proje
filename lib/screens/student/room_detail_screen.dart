import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/room_service.dart';
import '../../services/application_service.dart';
import '../../models/room_model.dart';
import '../../core/theme/app_theme.dart';

class RoomDetailScreen extends StatelessWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final roomService = RoomService();
    final appService = ApplicationService();

    return Scaffold(
      body: FutureBuilder<RoomModel?>(
        future: roomService.getRoom(roomId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Oda bulunamadı.'));
          }
          final room = snapshot.data!;
          final fillRatio = room.capacity > 0
              ? (room.currentOccupancy / room.capacity).clamp(0.0, 1.0)
              : 0.0;
          final color = room.isFull
              ? AppColors.red
              : room.availableSpots == 1
                  ? AppColors.orange
                  : AppColors.green;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white),
                  onPressed: () => context.go('/rooms'),
                ),
                title: Text('Oda ${room.number}'),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration:
                        BoxDecoration(gradient: AppColors.mainGradient),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.meeting_room_rounded,
                                color: Colors.white,
                                size: 42),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Oda ${room.number}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              room.isFull ? 'DOLU' : 'MÜSAİT',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
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
                    children: [
                      _InfoCard(room: room, fillRatio: fillRatio, color: color),
                      const SizedBox(height: 16),
                      _CapacityCard(
                          room: room, fillRatio: fillRatio, color: color),
                      const SizedBox(height: 20),
                      if (!auth.isAdmin)
                        FutureBuilder<bool>(
                          future: appService.hasActiveApplication(
                              auth.user!.uid, roomId),
                          builder: (context, snap) {
                            final hasApplied = snap.data ?? false;
                            if (room.isFull) {
                              return _StatusBanner(
                                color: AppColors.red,
                                icon: Icons.block_rounded,
                                message: 'Bu oda dolu, başvuru yapılamaz.',
                              );
                            }
                            if (hasApplied) {
                              return _StatusBanner(
                                color: AppColors.orange,
                                icon: Icons.hourglass_top_rounded,
                                message:
                                    'Bu odaya zaten başvurdunuz. Sonuç profilinizde görünecek.',
                              );
                            }
                            return _GradientActionButton(
                              label: 'Bu Odaya Başvur',
                              icon: Icons.assignment_turned_in_rounded,
                              onTap: () => context.go('/apply/$roomId'),
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final RoomModel room;
  final double fillRatio;
  final Color color;
  const _InfoCard(
      {required this.room, required this.fillRatio, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Oda Bilgileri',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          _Row(icon: Icons.layers_rounded, label: 'Kat', value: '${room.floor}. Kat'),
          const Divider(height: 20),
          _Row(icon: Icons.people_rounded, label: 'Oda Tipi', value: room.type),
          const Divider(height: 20),
          _Row(
              icon: Icons.king_bed_rounded,
              label: 'Kapasite',
              value: '${room.capacity} Kişi'),
        ],
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  final RoomModel room;
  final double fillRatio;
  final Color color;
  const _CapacityCard(
      {required this.room, required this.fillRatio, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doluluk Durumu',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _CircleStat(
                value: room.currentOccupancy,
                label: 'Mevcut',
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _CircleStat(
                value: room.availableSpots,
                label: 'Boş',
                color: color,
              ),
              const SizedBox(width: 12),
              _CircleStat(
                value: room.capacity,
                label: 'Kapasite',
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fillRatio,
              minHeight: 10,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '%${(fillRatio * 100).round()} Dolu',
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleStat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _CircleStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

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
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;
  const _StatusBanner(
      {required this.color, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradientActionButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: AppColors.mainGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
