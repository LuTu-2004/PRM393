import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import 'package:exe_matching/features/coordination/screens/moderator_dashboard_screen.dart';
import 'package:exe_matching/features/auth/bloc/auth_bloc.dart';
import 'package:exe_matching/features/auth/bloc/auth_event.dart';
import 'package:exe_matching/features/profile/widgets/storage_report_panel.dart';
import 'package:exe_matching/features/profile/widgets/remote_config_panel.dart';

/// Man hinh Ho so Sinh vien (Profile Tab)
/// Tuan thu BR-02 (Email FPT), BR-03 & BR-04 (MSSV trich xuat Major/Cohort), BR-05 (Hoan thien ho so ky nang)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _customSkillCtrl = TextEditingController();

  String _selectedCampus = 'HCM';
  String _selectedRole = 'Leader / Mobile Developer';
  String _selectedOrientation = 'Technology Startup';
  List<String> _skills = [];
  bool _isInitialized = false;

  final List<String> _commonSkillSuggestions = [
    'Flutter',
    '.NET Core',
    'Figma UI/UX',
    'Marketing',
    'Nghiên cứu thị trường',
    'Business Model Canvas',
    'Pitching',
    'React',
    'Data Analytics',
  ];

  final List<String> _orientationOptions = [
    'Technology Startup',
    'FinTech',
    'EdTech',
    'GreenTech & ESG',
    'E-Commerce',
    'HealthTech & AI',
    'Fintech Edu Startup',
  ];

  final List<String> _roleOptions = [
    'Leader / Mobile Developer',
    'Frontend Developer',
    'Backend Developer',
    'UI/UX Designer',
    'Business Analyst',
    'Marketing / Growth',
    'Product Manager',
    'Developer / Team Member',
    'Moderator / Advisor',
  ];

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const LoadProfileEvent());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _customSkillCtrl.dispose();
    super.dispose();
  }

  void _populateUserData(UserModel user) {
    if (_isInitialized) return;
    _nameCtrl.text = user.fullName;
    _bioCtrl.text = user.bio ?? '';
    _selectedCampus = user.campus ?? 'HCM';
    
    if (user.desiredRole != null && user.desiredRole!.isNotEmpty) {
      _selectedRole = user.desiredRole!;
      if (!_roleOptions.contains(_selectedRole)) {
        _roleOptions.insert(0, _selectedRole);
      }
    } else {
      _selectedRole = _roleOptions.first;
    }

    if (user.orientation != null && user.orientation!.isNotEmpty) {
      _selectedOrientation = user.orientation!;
      if (!_orientationOptions.contains(_selectedOrientation)) {
        _orientationOptions.insert(0, _selectedOrientation);
      }
    } else {
      _selectedOrientation = _orientationOptions.first;
    }

    _skills = List<String>.from(user.skills);
    _isInitialized = true;
  }

  void _addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty || _skills.any((s) => s.toLowerCase() == trimmed.toLowerCase())) return;
    setState(() {
      _skills.add(trimmed);
      _customSkillCtrl.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  void _saveProfile(UserModel originalUser) {
    if (!_formKey.currentState!.validate()) return;

    final updated = originalUser.copyWith(
      fullName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      campus: _selectedCampus,
      desiredRole: _selectedRole,
      orientation: _selectedOrientation,
      skills: _skills,
      isProfileComplete: _skills.isNotEmpty && _selectedOrientation.isNotEmpty,
    );

    context.read<ProfileBloc>().add(UpdateProfileEvent(updated));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ Sinh Viên'),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoadedState && state.successMessage != null) {
            try {
              BlocProvider.of<AuthBloc>(context, listen: false).add(CheckAuthStatusEvent());
            } catch (_) {}
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is ProfileErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProfileLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileLoadedState) {
            _populateUserData(state.user);
            final user = state.user;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. User Identity Header Card
                    _buildIdentityHeader(user),
                    const SizedBox(height: 16),

                    // 2. Profile Completeness Banner (BR-05)
                    _buildCompletenessBanner(user.isProfileComplete),
                    const SizedBox(height: 20),

                    // 3. Ho va Ten
                    const Text('Họ và Tên *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
                    ),
                    const SizedBox(height: 16),

                    // 4. Vai tro mong muon trong du an
                    const Text('Vai trò mong muốn trong nhóm *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _roleOptions.contains(_selectedRole) ? _selectedRole : _roleOptions.first,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                      ),
                      items: _roleOptions.toSet().map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // 5. Dinh huong khoi nghiep
                    const Text('Định hướng dự án khởi nghiệp *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _orientationOptions.contains(_selectedOrientation) ? _selectedOrientation : _orientationOptions.first,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                      ),
                      items: _orientationOptions.toSet().map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 14)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedOrientation = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // 6. Ky nang (Skills) - BR-05
                    const Text('Kỹ năng của bạn (Skills) *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text(
                      'Hệ thống AI Matching sẽ dựa trên các kỹ năng này để tìm phòng đang thiếu vị trí của bạn.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),

                    // Danh sach ky nang hien tai (Chips)
                    if (_skills.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skills.map((skill) {
                          return Chip(
                            label: Text(skill, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primary),
                            onDeleted: () => _removeSkill(skill),
                            side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          );
                        }).toList(),
                      )
                    else
                      const Text('Chưa có kỹ năng nào. Vui lòng thêm bên dưới.', style: TextStyle(fontSize: 12, color: AppColors.error)),
                    const SizedBox(height: 12),

                    // Goi y ky nang them nhanh
                    const Text('Gợi ý thêm nhanh:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _commonSkillSuggestions.where((s) => !_skills.contains(s)).take(6).map((suggestion) {
                        return ActionChip(
                          label: Text('+ $suggestion', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.cardBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onPressed: () => _addSkill(suggestion),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // O nhap custom skill
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customSkillCtrl,
                            decoration: InputDecoration(
                              hintText: 'Nhập kỹ năng khác (ví dụ: SEO, AI Prompting...)',
                              hintStyle: const TextStyle(fontSize: 13),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                            ),
                            onSubmitted: _addSkill,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _addSkill(_customSkillCtrl.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Thêm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 7. Gioi thieu ban than (Bio)
                    const Text('Giới thiệu bản thân (Bio)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _bioCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Mô tả ngắn về kinh nghiệm, mục tiêu dự án và mong muốn hợp tác...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 8. Nut Luu Ho So
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state.isSaving ? null : () => _saveProfile(user),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: state.isSaving
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Lưu Hồ Sơ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 9. Loi vao danh rieng cho Giang Vien / Dieu Phoi Vien
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Góc Giảng Viên', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                SizedBox(height: 2),
                                Text('Tiến độ toàn trường & can thiệp', style: TextStyle(fontSize: 11, color: Colors.white70)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ModeratorDashboardScreen(),
                                ),
                              );
                            },
                            child: const Text('Truy cập', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Firebase Cloud Storage Panel (Lab 3)
                    const StorageReportPanel(),
                      const SizedBox(height: 16),
                      // Firebase Remote Config Panel (Lab 3)
                      const RemoteConfigPanel(),
                    const SizedBox(height: 16),

                    // 10. Nut Dang Xuat (Sign Out)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<AuthBloc>().add(SignOutEvent());
                        },
                        icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
                        label: const Text('Đăng Xuất Tài Khoản', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildIdentityHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              user.major ?? 'SE',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.cohort ?? 'K18',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Email FPT verified badge (BR-02)
                Row(
                  children: [
                    const Icon(Icons.verified, size: 14, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'MSSV: ${user.studentCode ?? "SE180123"} • Ngành: ${user.major ?? "SE"}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletenessBanner(bool isComplete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isComplete ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle_outline : Icons.info_outline,
            size: 20,
            color: isComplete ? const Color(0xFF16A34A) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isComplete ? 'Hồ sơ đã sẵn sàng ghép nhóm' : 'Cần hoàn thiện hồ sơ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isComplete ? const Color(0xFF15803D) : const Color(0xFF92400E),
                  ),
                ),
                Text(
                  isComplete
                      ? 'Hệ thống AI sẽ dùng kỹ năng của bạn để tính điểm Matching Score.'
                      : 'Vui lòng bổ sung ít nhất 1 kỹ năng và chọn định hướng khởi nghiệp.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isComplete ? const Color(0xFF166534) : const Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


