import 'package:flutter/material.dart';
import 'package:exe_matching/services/remote_config_service.dart';

/// Panel hien thi va lam moi Firebase Remote Config
/// Demo thay doi tham so tu Console ma khong can build lai app
/// Yeu cau Lab 3: toi thieu 2 tham so co the quan sat duoc
class RemoteConfigPanel extends StatefulWidget {
  const RemoteConfigPanel({super.key});

  @override
  State<RemoteConfigPanel> createState() => _RemoteConfigPanelState();
}

class _RemoteConfigPanelState extends State<RemoteConfigPanel> {
  bool _isRefreshing = false;
  Map<String, dynamic>? _lastValues;

  @override
  void initState() {
    super.initState();
    _loadCurrentValues();
  }

  void _loadCurrentValues() {
    setState(() {
      _lastValues = {
        'max_pending_requests': RemoteConfigService.maxPendingRequests,
        'voting_duration_hours': RemoteConfigService.votingDurationHours,
        'show_matching_banner': RemoteConfigService.showMatchingBanner,
      };
    });
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      final values = await RemoteConfigService.refresh();
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _lastValues = values;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Remote Config đã được cập nhật từ Firebase Console!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.tune, color: Colors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Firebase Remote Config', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Cấu hình từ xa — không cần build lại', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _isRefreshing ? null : _refresh,
                  icon: _isRefreshing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, color: Colors.purple),
                  tooltip: 'Tải lại từ Firebase Console',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_lastValues != null) ...[
              _ConfigRow(
                icon: Icons.mail_outline,
                label: 'max_pending_requests',
                value: '${_lastValues!['max_pending_requests']}',
                description: 'Số request chờ tối đa',
              ),
              const SizedBox(height: 8),
              _ConfigRow(
                icon: Icons.timer_outlined,
                label: 'voting_duration_hours',
                value: '${_lastValues!['voting_duration_hours']}h',
                description: 'Thời gian bỏ phiếu kín',
              ),
              const SizedBox(height: 8),
              _ConfigRow(
                icon: Icons.auto_awesome,
                label: 'show_matching_banner',
                value: _lastValues!['show_matching_banner'] == true ? '✅ Bật' : '❌ Tắt',
                description: 'Hiển thị banner gợi ý Matching',
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '💡 Đổi giá trị trên Firebase Console > Remote Config và bấm nút Refresh để kiểm chứng.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String description;

  const _ConfigRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.black87)),
              Text(description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple)),
        ),
      ],
    );
  }
}
