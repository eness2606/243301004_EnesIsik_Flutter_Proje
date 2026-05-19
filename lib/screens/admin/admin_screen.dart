import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/application_service.dart';
import '../../services/room_service.dart';
import '../../models/application_model.dart';
import '../../models/room_model.dart';
import '../../models/log_model.dart';
import '../../core/theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yönetim Paneli',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Hoş geldiniz, ${auth.user?.name ?? ''}',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        flexibleSpace:
            Container(decoration: BoxDecoration(gradient: AppColors.mainGradient)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () => auth.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 20), text: 'Özet'),
            Tab(icon: Icon(Icons.assignment_outlined, size: 20), text: 'Başvurular'),
            Tab(icon: Icon(Icons.meeting_room_outlined, size: 20), text: 'Odalar'),
            Tab(icon: Icon(Icons.history, size: 20), text: 'Loglar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          const _DashboardTab(),
          _ApplicationsTab(),
          _RoomsTab(),
          const _LogsTab(),
        ],
      ),
      floatingActionButton: _tab.index == 2
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Oda Ekle'),
              backgroundColor: AppColors.primary,
              onPressed: () => _showAddRoomDialog(context),
            )
          : null,
    );
  }

  void _showAddRoomDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const _AddRoomDialog());
  }
}

// ─────────────── Dashboard Tab ───────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final roomService = RoomService();
    final appService = ApplicationService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personel bilgi kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.mainGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.manage_accounts_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.user?.name ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      const Text('Yurt Görevlisi',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(auth.user?.email ?? '',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Oda İstatistikleri',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),

          StreamBuilder<List<RoomModel>>(
            stream: roomService.getRooms(),
            builder: (context, snap) {
              final rooms = snap.data ?? [];
              final total = rooms.length;
              final full = rooms.where((r) => r.isFull).length;
              final available = total - full;
              final totalCapacity =
                  rooms.fold(0, (s, r) => s + r.capacity);
              final totalOccupancy =
                  rooms.fold(0, (s, r) => s + r.currentOccupancy);

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              label: 'Toplam Oda',
                              value: '$total',
                              icon: Icons.meeting_room_rounded,
                              color: AppColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatCard(
                              label: 'Müsait',
                              value: '$available',
                              icon: Icons.check_circle_outline,
                              color: AppColors.green)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              label: 'Dolu',
                              value: '$full',
                              icon: Icons.block_outlined,
                              color: AppColors.red)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _StatCard(
                              label: 'Doluluk',
                              value: totalCapacity > 0
                                  ? '%${((totalOccupancy / totalCapacity) * 100).round()}'
                                  : '%0',
                              icon: Icons.pie_chart_outline,
                              color: AppColors.orange)),
                    ],
                  ),
                  if (rooms.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _OccupancyBar(
                        occupancy: totalOccupancy, capacity: totalCapacity),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 20),
          const Text('Bekleyen Başvurular',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 10),

          StreamBuilder<List<ApplicationModel>>(
            stream: appService.getAllApplications(),
            builder: (context, snap) {
              final apps = snap.data ?? [];
              final pending =
                  apps.where((a) => a.status == 'pending').length;
              final approved =
                  apps.where((a) => a.status == 'approved').length;
              final rejected =
                  apps.where((a) => a.status == 'rejected').length;

              return Row(
                children: [
                  Expanded(
                      child: _StatCard(
                          label: 'Beklemede',
                          value: '$pending',
                          icon: Icons.hourglass_top_rounded,
                          color: AppColors.orange)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatCard(
                          label: 'Onaylanan',
                          value: '$approved',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.green)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatCard(
                          label: 'Reddedilen',
                          value: '$rejected',
                          icon: Icons.cancel_rounded,
                          color: AppColors.red)),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupancyBar extends StatelessWidget {
  final int occupancy;
  final int capacity;
  const _OccupancyBar(
      {required this.occupancy, required this.capacity});

  @override
  Widget build(BuildContext context) {
    final ratio =
        capacity > 0 ? (occupancy / capacity).clamp(0.0, 1.0) : 0.0;
    final color = ratio > 0.85
        ? AppColors.red
        : ratio > 0.6
            ? AppColors.orange
            : AppColors.green;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Genel Doluluk',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text('$occupancy / $capacity kişi',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────── Başvurular Tab ───────────────

class _ApplicationsTab extends StatelessWidget {
  final _appService = ApplicationService();
  _ApplicationsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ApplicationModel>>(
      stream: _appService.getAllApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final apps = snapshot.data ?? [];
        if (apps.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                const Text('Henüz başvuru bulunmuyor.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        final pending = apps.where((a) => a.status == 'pending').toList();
        final others = apps.where((a) => a.status != 'pending').toList();
        final sorted = [...pending, ...others];

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: sorted.length,
          itemBuilder: (context, i) => _AdminAppCard(app: sorted[i]),
        );
      },
    );
  }
}

class _AdminAppCard extends StatelessWidget {
  final ApplicationModel app;
  final _appService = ApplicationService();
  _AdminAppCard({required this.app});

  Color get _statusColor {
    switch (app.status) {
      case 'approved': return AppColors.green;
      case 'rejected': return AppColors.red;
      default: return AppColors.orange;
    }
  }

  String get _statusText {
    switch (app.status) {
      case 'approved': return 'Onaylandı';
      case 'rejected': return 'Reddedildi';
      default: return 'Beklemede';
    }
  }

  IconData get _statusIcon {
    switch (app.status) {
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      default: return Icons.hourglass_top;
    }
  }

  Future<void> _updateStatus(BuildContext context, String status,
      String adminId, String adminEmail) async {
    await _appService.updateStatus(
      adminId: adminId,
      adminEmail: adminEmail,
      applicationId: app.id,
      userId: app.userId,
      roomId: app.roomId,
      status: status,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          status == 'approved' ? 'Başvuru onaylandı.' : 'Başvuru reddedildi.'),
      backgroundColor: status == 'approved' ? AppColors.green : AppColors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text(app.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('No: ${app.studentNo}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(_statusText,
                    style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.meeting_room_outlined,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('Oda ${app.roomNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(DateFormat('dd.MM.yyyy HH:mm').format(app.date),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          if (app.status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateStatus(context, 'approved',
                        auth.user!.uid, auth.user!.email),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded,
                              color: AppColors.green, size: 18),
                          SizedBox(width: 6),
                          Text('Onayla',
                              style: TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateStatus(context, 'rejected',
                        auth.user!.uid, auth.user!.email),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.red.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded,
                              color: AppColors.red, size: 18),
                          SizedBox(width: 6),
                          Text('Reddet',
                              style: TextStyle(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────── Odalar Tab ───────────────

class _RoomsTab extends StatelessWidget {
  final _roomService = RoomService();
  _RoomsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoomModel>>(
      stream: _roomService.getRooms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rooms = snapshot.data ?? [];
        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.meeting_room_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                const Text('Henüz oda bulunmuyor.',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                const Text('Sağ alttaki + butonuna basarak oda ekleyin.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rooms.length,
          itemBuilder: (context, i) => _AdminRoomCard(room: rooms[i]),
        );
      },
    );
  }
}

class _AdminRoomCard extends StatelessWidget {
  final RoomModel room;
  final _roomService = RoomService();
  _AdminRoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fillRatio =
        room.capacity > 0 ? room.currentOccupancy / room.capacity : 0.0;
    final color = room.isFull
        ? AppColors.red
        : fillRatio > 0.7
            ? AppColors.orange
            : AppColors.green;

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
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.mainGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.meeting_room_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Oda ${room.number}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                          room.isFull
                              ? 'Dolu'
                              : '${room.availableSpots} Boş',
                          style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text('${room.floor}. Kat  •  ${room.type}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fillRatio.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.grey[100],
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${room.currentOccupancy}/${room.capacity}',
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppColors.primary, size: 20),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _EditRoomDialog(room: room),
                ),
                tooltip: 'Düzenle',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.red, size: 20),
                onPressed: () => _confirmDelete(context, auth),
                tooltip: 'Sil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Odayı Sil'),
        content: Text('Oda ${room.number} silinecek. Emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil',
                  style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await _roomService.deleteRoom(
        userId: auth.user!.uid,
        userEmail: auth.user!.email,
        roomId: room.id,
        roomNumber: room.number,
      );
    }
  }
}

// ─────────────── Loglar Tab ───────────────

class _LogsTab extends StatelessWidget {
  const _LogsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                const Text('Henüz log kaydı yok.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final log = LogModel.fromMap(data, docs[i].id);
            return _LogCard(log: log);
          },
        );
      },
    );
  }
}

class _LogCard extends StatelessWidget {
  final LogModel log;
  const _LogCard({required this.log});

  Color get _actionColor {
    switch (log.action) {
      case 'GİRİŞ': return AppColors.primary;
      case 'ÇIKIŞ': return AppColors.textSecondary;
      case 'KAYIT': return Colors.purple;
      case 'ODA_EKLEME': return AppColors.green;
      case 'ODA_SILME': return AppColors.red;
      case 'ODA_GUNCELLEME': return AppColors.orange;
      case 'BASVURU_OLUSTURMA': return AppColors.orange;
      case 'BASVURU_GUNCELLEME': return Colors.teal;
      default: return Colors.blueGrey;
    }
  }

  IconData get _actionIcon {
    switch (log.action) {
      case 'GİRİŞ': return Icons.login_rounded;
      case 'ÇIKIŞ': return Icons.logout_rounded;
      case 'KAYIT': return Icons.person_add_rounded;
      case 'ODA_EKLEME': return Icons.add_home_rounded;
      case 'ODA_SILME': return Icons.delete_rounded;
      case 'ODA_GUNCELLEME': return Icons.edit_rounded;
      case 'BASVURU_OLUSTURMA': return Icons.assignment_add;
      case 'BASVURU_GUNCELLEME': return Icons.assignment_turned_in_rounded;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _actionColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_actionIcon, color: _actionColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.details,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(log.userEmail,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _actionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(log.action,
                    style: TextStyle(
                        color: _actionColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd.MM HH:mm')
                    .format(log.timestamp.toLocal()),
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────── Oda Ekle Dialog ───────────────

class _AddRoomDialog extends StatefulWidget {
  const _AddRoomDialog();

  @override
  State<_AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<_AddRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  String _type = '2 Kişilik';
  bool _loading = false;
  final _roomService = RoomService();

  @override
  void dispose() {
    _numberCtrl.dispose();
    _floorCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final room = RoomModel(
      id: '',
      number: _numberCtrl.text.trim(),
      floor: int.parse(_floorCtrl.text),
      capacity: int.parse(_capacityCtrl.text),
      currentOccupancy: 0,
      type: _type,
    );
    await _roomService.addRoom(
        userId: auth.user!.uid,
        userEmail: auth.user!.email,
        room: room);
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _RoomFormDialog(
        title: 'Yeni Oda Ekle',
        formKey: _formKey,
        numberCtrl: _numberCtrl,
        floorCtrl: _floorCtrl,
        capacityCtrl: _capacityCtrl,
        type: _type,
        loading: _loading,
        onTypeChanged: (v) => setState(() => _type = v),
        onSave: _save,
      );
}

// ─────────────── Oda Düzenle Dialog ───────────────

class _EditRoomDialog extends StatefulWidget {
  final RoomModel room;
  const _EditRoomDialog({required this.room});

  @override
  State<_EditRoomDialog> createState() => _EditRoomDialogState();
}

class _EditRoomDialogState extends State<_EditRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numberCtrl;
  late TextEditingController _floorCtrl;
  late TextEditingController _capacityCtrl;
  late String _type;
  bool _loading = false;
  final _roomService = RoomService();

  @override
  void initState() {
    super.initState();
    _numberCtrl = TextEditingController(text: widget.room.number);
    _floorCtrl =
        TextEditingController(text: widget.room.floor.toString());
    _capacityCtrl =
        TextEditingController(text: widget.room.capacity.toString());
    _type = widget.room.type;
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _floorCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final updated = RoomModel(
      id: widget.room.id,
      number: _numberCtrl.text.trim(),
      floor: int.parse(_floorCtrl.text),
      capacity: int.parse(_capacityCtrl.text),
      currentOccupancy: widget.room.currentOccupancy,
      type: _type,
    );
    await _roomService.updateRoom(
        userId: auth.user!.uid,
        userEmail: auth.user!.email,
        room: updated);
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => _RoomFormDialog(
        title: 'Odayı Düzenle',
        formKey: _formKey,
        numberCtrl: _numberCtrl,
        floorCtrl: _floorCtrl,
        capacityCtrl: _capacityCtrl,
        type: _type,
        loading: _loading,
        onTypeChanged: (v) => setState(() => _type = v),
        onSave: _save,
      );
}

// ─────────────── Ortak Form Widget ───────────────

class _RoomFormDialog extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final TextEditingController numberCtrl;
  final TextEditingController floorCtrl;
  final TextEditingController capacityCtrl;
  final String type;
  final bool loading;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onSave;

  const _RoomFormDialog({
    required this.title,
    required this.formKey,
    required this.numberCtrl,
    required this.floorCtrl,
    required this.capacityCtrl,
    required this.type,
    required this.loading,
    required this.onTypeChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.meeting_room_rounded,
              color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: numberCtrl,
                decoration: const InputDecoration(
                    labelText: 'Oda No', prefixIcon: Icon(Icons.tag)),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Zorunlu alan' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: floorCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Kat', prefixIcon: Icon(Icons.layers)),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Zorunlu alan';
                  if (int.tryParse(v) == null) return 'Sayı girin';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: capacityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Kapasite',
                    prefixIcon: Icon(Icons.people)),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Zorunlu alan';
                  final n = int.tryParse(v);
                  if (n == null || n < 1) return 'Geçerli sayı girin';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(
                    labelText: 'Oda Tipi',
                    prefixIcon: Icon(Icons.king_bed_outlined)),
                items: const [
                  DropdownMenuItem(value: '1 Kişilik', child: Text('1 Kişilik')),
                  DropdownMenuItem(value: '2 Kişilik', child: Text('2 Kişilik')),
                  DropdownMenuItem(value: '3 Kişilik', child: Text('3 Kişilik')),
                  DropdownMenuItem(value: '4 Kişilik', child: Text('4 Kişilik')),
                ],
                onChanged: (v) => onTypeChanged(v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal')),
        loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 40)),
                child: const Text('Kaydet'),
              ),
      ],
    );
  }
}
