import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/config/app_config.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/features/auth/bloc/auth_bloc.dart';
import 'package:exe_matching/features/auth/bloc/auth_state.dart';
import '../bloc/room_bloc.dart';
import '../bloc/room_event.dart';

/// Man hinh Tao phong ghep nhom moi
/// Tuan thu BR-06, BR-07, BR-08, BR-09, BR-10
class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedSubject = 'EXE101'; // BR-09: EXE101 hoac EXE201
  final String _selectedSemester = 'FALL2026';
  bool _isPublic = true; // BR-10: Public hay Private
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();

    UserModel? currentUser;
    try {
      final authState = BlocProvider.of<AuthBloc>(context, listen: false).state;
      if (authState is AuthenticatedState) {
        currentUser = authState.user;
      }
    } catch (_) {}

    final leader = RoomMemberModel(
      userId: currentUser?.id ?? 'uid_se_001',
      fullName: currentUser?.fullName ?? 'Nguyễn Văn An',
      studentCode: currentUser?.studentCode ?? 'SE180123',
      major: currentUser?.major ?? 'SE',
      role: 'Leader',
      joinedAt: now,
    );

    final newRoom = RoomModel(
      id: 'room_' + now.millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      subjectCode: _selectedSubject,
      semesterId: _selectedSemester,
      leaderId: leader.userId,
      leaderName: leader.fullName,
      isPublic: _isPublic,
      status: 'open',
      maxMembers: AppConfig.TEAM_MAX_MEMBERS,
      minMembers: AppConfig.TEAM_MIN_MEMBERS,
      members: [leader],
      createdAt: now,
    );

    // Goi BLoC de tao phong moi
    context.read<RoomBloc>().add(CreateRoomEvent(newRoom));

    // Ghi log Firebase Analytics (Lab 3 requirement)
    await AnalyticsService.logRoomCreated(
      subjectCode: _selectedSubject,
      isPublic: _isPublic,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Tạo phòng "\${newRoom.name}" thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Phòng Dự Án EXE'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner huong dan nghiep vu
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Quy định môn EXE: Mỗi sinh viên chỉ làm Trưởng nhóm hoặc thành viên 1 phòng trong học kỳ. Số lượng thành viên hợp lệ từ 4 đến 5 người.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Chon mon hoc (BR-09)
              const Text(
                'Môn học *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSubjectOption('EXE101', 'Khởi nghiệp trải nghiệm 1'),
                  const SizedBox(width: 12),
                  _buildSubjectOption('EXE201', 'Khởi nghiệp trải nghiệm 2'),
                ],
              ),
              const SizedBox(height: 20),

              // Ten phong
              const Text(
                'Tên phòng / Tên dự án *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: EcoPackaging, SmartEdu, FinLife...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập tên phòng dự án';
                  if (val.trim().length < 4) return 'Tên phòng phải có ít nhất 4 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Mo ta du an
              const Text(
                'Mô tả ý tưởng dự án *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Mô tả ngắn gọn về bài toán dự án giải quyết, khách hàng mục tiêu và các vị trí cần tuyển thêm...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập mô tả ý tưởng dự án';
                  if (val.trim().length < 15) return 'Mô tả dự án nên có ít nhất 15 ký tự để các bạn khác nắm rõ';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Che do phong: Public / Private
              Card(
                child: SwitchListTile(
                  title: const Text(
                    'Phòng công khai (Public Room)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    _isPublic
                        ? 'Mọi sinh viên đều có thể tìm thấy và gửi yêu cầu xin gia nhập.'
                        : 'Chỉ những sinh viên được bạn mời trực tiếp mới thấy phòng này.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  value: _isPublic,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _isPublic = val),
                ),
              ),
              const SizedBox(height: 32),

              // Nut Hoan tat tao phong
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreate,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Hoàn Tất Tạo Phòng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectOption(String code, String desc) {
    final isSelected = _selectedSubject == code;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedSubject = code),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  if (isSelected) const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
