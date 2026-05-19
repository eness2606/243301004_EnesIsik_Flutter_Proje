import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/application_service.dart';
import '../../services/room_service.dart';
import '../../models/application_model.dart';
import '../../models/room_model.dart';
import '../../core/theme/app_theme.dart';

class ApplyScreen extends StatefulWidget {
  final String roomId;
  const ApplyScreen({super.key, required this.roomId});

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _appService = ApplicationService();
  final _roomService = RoomService();
  bool _loading = false;
  RoomModel? _room;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    final r = await _roomService.getRoom(widget.roomId);
    setState(() => _room = r);
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user!;
    setState(() => _loading = true);

    final alreadyApplied =
        await _appService.hasActiveApplication(user.uid, widget.roomId);
    if (alreadyApplied) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bu odaya zaten aktif bir başvurunuz bulunuyor.'),
          backgroundColor: AppColors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final application = ApplicationModel(
      id: '',
      userId: user.uid,
      userName: user.name,
      studentNo: user.studentNo,
      roomId: widget.roomId,
      roomNumber: _room?.number ?? '',
      status: 'pending',
      date: DateTime.now(),
    );

    await _appService.createApplication(
      userId: user.uid,
      userEmail: user.email,
      application: application,
    );

    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Başvurunuz alındı! Onay bekleniyor.'),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    context.go('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    return Scaffold(
      body: _room == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 160,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () =>
                        context.go('/rooms/${widget.roomId}'),
                  ),
                  title: const Text('Oda Başvurusu'),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                          gradient: AppColors.mainGradient),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 48),
                            const Icon(
                                Icons.assignment_turned_in_rounded,
                                color: Colors.white,
                                size: 40),
                            const SizedBox(height: 8),
                            Text(
                              'Oda ${_room!.number} Başvurusu',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
                        _InfoSection(
                          title: 'Başvuran Bilgileri',
                          icon: Icons.person_outline,
                          items: [
                            _Item('Ad Soyad', user.name),
                            _Item('Öğrenci No', user.studentNo),
                            _Item('E-posta', user.email),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoSection(
                          title: 'Oda Bilgileri',
                          icon: Icons.meeting_room_outlined,
                          items: [
                            _Item('Oda No', _room!.number),
                            _Item('Oda Tipi', _room!.type),
                            _Item('Kat', '${_room!.floor}. Kat'),
                            _Item('Boş Yer',
                                '${_room!.availableSpots}/${_room!.capacity}'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.orange
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppColors.orange, size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Başvurunuz yurt görevlisi tarafından incelenecek ve sonuç profilinizde görüntülenecektir.',
                                  style: TextStyle(
                                      color: AppColors.orange,
                                      fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _loading
                            ? const Center(
                                child: CircularProgressIndicator())
                            : GestureDetector(
                                onTap: _submit,
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.mainGradient,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send_rounded,
                                          color: Colors.white),
                                      SizedBox(width: 10),
                                      Text('Başvuruyu Gönder',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 15)),
                                    ],
                                  ),
                                ),
                              ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text('Vazgeç'),
                          onPressed: () =>
                              context.go('/rooms/${widget.roomId}'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
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

class _Item {
  final String label;
  final String value;
  _Item(this.label, this.value);
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_Item> items;
  const _InfoSection(
      {required this.title, required this.icon, required this.items});

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
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
            ],
          ),
          const Divider(height: 16),
          ...items.asMap().entries.map((e) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(e.value.label,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                        const Spacer(),
                        Text(e.value.value,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  if (e.key < items.length - 1)
                    const Divider(height: 8),
                ],
              )),
        ],
      ),
    );
  }
}
