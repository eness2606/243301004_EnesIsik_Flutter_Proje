import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/room_service.dart';
import '../../models/room_model.dart';
import '../../core/theme/app_theme.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _roomService = RoomService();
  bool _showOnlyAvailable = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: StreamBuilder<List<RoomModel>>(
        stream: _roomService.getRooms(),
        builder: (context, snapshot) {
          final allRooms = snapshot.data ?? [];
          final rooms = _showOnlyAvailable
              ? allRooms.where((r) => !r.isFull).toList()
              : allRooms;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(auth, allRooms),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      const Text('Yalnızca Müsait Odalar',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 13)),
                      const Spacer(),
                      Switch.adaptive(
                        value: _showOnlyAvailable,
                        activeTrackColor: AppColors.primary,
                        onChanged: (v) =>
                            setState(() => _showOnlyAvailable = v),
                      ),
                    ],
                  ),
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (rooms.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.meeting_room_outlined,
                            size: 64,
                            color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          _showOnlyAvailable
                              ? 'Müsait oda bulunmuyor.'
                              : 'Henüz oda eklenmemiş.',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _RoomCard(room: rooms[i]),
                      childCount: rooms.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(AuthProvider auth, List<RoomModel> rooms) {
    final available = rooms.where((r) => !r.isFull).length;
    final full = rooms.where((r) => r.isFull).length;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      title: const Text('Odalar'),
      actions: [
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          onPressed: () => context.go('/profile'),
          tooltip: 'Profil',
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => auth.logout(),
          tooltip: 'Çıkış',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: AppColors.mainGradient),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 60, 20, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yurt Odaları',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatPill(
                          label: 'Toplam',
                          value: rooms.length,
                          color: Colors.white),
                      const SizedBox(width: 8),
                      _StatPill(
                          label: 'Müsait',
                          value: available,
                          color: AppColors.green),
                      const SizedBox(width: 8),
                      _StatPill(
                          label: 'Dolu',
                          value: full,
                          color: AppColors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  const _RoomCard({required this.room});

  Color get _statusColor => room.isFull
      ? AppColors.red
      : room.availableSpots == 1
          ? AppColors.orange
          : AppColors.green;

  String get _statusLabel =>
      room.isFull ? 'Dolu' : '${room.availableSpots} Boş Yer';

  @override
  Widget build(BuildContext context) {
    final fillRatio = room.capacity > 0
        ? (room.currentOccupancy / room.capacity).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () => context.go('/rooms/${room.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.mainGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.meeting_room_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Oda ${room.number}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                _statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel,
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${room.floor}. Kat  •  ${room.type}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: fillRatio,
                              minHeight: 6,
                              backgroundColor:
                                  Colors.grey[100],
                              valueColor:
                                  AlwaysStoppedAnimation(_statusColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${room.currentOccupancy}/${room.capacity}',
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
