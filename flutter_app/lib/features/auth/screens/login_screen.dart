import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Man hinh Dang Nhap & Xac Thuc He Thong
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showTermsDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gavel_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Cam Kết Quy Chế',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chào mừng ${user.fullName} (${user.email}) đến với Hệ thống Ghép nhóm Đa ngành EXE!',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              const Text(
                'Để đảm bảo tính công bằng và chất lượng môn học EXE101/EXE201, bạn vui lòng xác nhận các quy định sau:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 12),
              _buildTermItem('1. Nhóm khởi nghiệp hợp lệ phải có từ 4 đến 5 thành viên.'),
              _buildTermItem('2. Không được vượt quá 50% thành viên cùng chuyên ngành trong một nhóm.'),
              _buildTermItem('3. Mỗi sinh viên chỉ tham gia duy nhất 1 nhóm tại một học kỳ.'),
              _buildTermItem('4. Tôn trọng kết quả bỏ phiếu kín của nhóm và giữ bí mật bầu cử.'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thời gian cam kết của bạn sẽ được lưu vết trên hệ thống để đối chiếu quy chế khi cần thiết.',
                        style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthBloc>().add(AcceptTermsEvent(user.id));
              },
              child: const Text(
                'Tôi Đồng Ý & Tiếp Tục',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is NeedsTermsAcceptanceState) {
            _showTermsDialog(context, state.user);
          } else if (state is UnauthenticatedState && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is AuthenticatedState && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoadingState;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F172A), // Slate đen sang trọng
                  Color(0xFF1E293B),
                  Color(0xFF0F172A),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 1. Logo & Badge Dai hoc FPT
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school, color: Color(0xFFF97316), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'FPT UNIVERSITY • EXE MATCHING',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Icon App Hub
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF97316).withOpacity(0.35),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.hub_rounded, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // 3. Ten He thong & Slogan
                      const Text(
                        'EXE Team Matching',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Nền tảng ghép nhóm đa ngành khởi nghiệp\nMôn EXE101 & EXE201',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 4. Khung Nhap Email FPT & Mat Khau
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.14)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.mark_email_read_outlined, size: 16, color: Color(0xFFF97316)),
                                SizedBox(width: 8),
                                Text(
                                  'Đăng Nhập Bằng Email FPT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Ví dụ: tulpnse185102@fpt.edu.vn',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
                                prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFFF97316), size: 18),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.25),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Nhập mật khẩu (tùy chọn hoặc nếu có)',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12),
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFF97316), size: 18),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.25),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        final email = _emailController.text.trim();
                                        final password = _passwordController.text.trim();
                                        if (email.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Vui lòng nhập email trường FPT!'),
                                              backgroundColor: AppColors.warning,
                                            ),
                                          );
                                          return;
                                        }
                                        context.read<AuthBloc>().add(
                                          SignInWithFptEmailEvent(
                                            email,
                                            password: password.isNotEmpty ? password : null,
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                label: const Text(
                                  'Xác Thực Email & Đăng Nhập',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF97316),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Tự động trích xuất MSSV, Ngành và Khóa đào tạo.\n• Chỉ hỗ trợ tài khoản email trường ĐH FPT.',
                              style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.5), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 5. Nut Dang Nhap Google (@fpt.edu.vn)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => context.read<AuthBloc>().add(SignInWithGoogleEvent()),
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                                )
                              : Image.network(
                                  'https://www.gstatic.com/images/branding/product/1x/gsa_512dp.png',
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.login, color: Colors.black87),
                                ),
                          label: const Text(
                            'Đăng nhập với Google (@fpt.edu.vn)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 6. Divider "Hoac trai nghiem nhanh Demo"
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'HOẶC TRẢI NGHIỆM DEMO NHANH',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.4),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.15))),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 7. Nut Demo Sinh Vien
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => context.read<AuthBloc>().add(
                                    const SignInDemoEvent(role: 'student'),
                                  ),
                          icon: const Icon(Icons.school_outlined, size: 18, color: Color(0xFF38BDF8)),
                          label: const Text(
                            'Đăng Nhập Demo: Sinh Viên (Nguyễn Văn An)',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            backgroundColor: Colors.white.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 8. Nut Demo Giang Vien (Moderator)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => context.read<AuthBloc>().add(
                                    const SignInDemoEvent(role: 'moderator'),
                                  ),
                          icon: const Icon(Icons.admin_panel_settings_outlined, size: 18, color: Color(0xFFFBBF24)),
                          label: const Text(
                            'Đăng Nhập Demo: Giảng Viên (Moderator)',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            backgroundColor: Colors.white.withOpacity(0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 9. Footer bao mat
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, size: 13, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(width: 6),
                          Text(
                            'Xác thực an toàn • Bảo mật thông tin sinh viên FPT',
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
