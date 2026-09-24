import 'dart:io';

/// An IPv4 address of this laptop that phones on the LAN can reach.
class LanAddress {
  const LanAddress({required this.interfaceName, required this.ip});

  final String interfaceName;
  final String ip;

  /// Windows Mobile Hotspot always uses this subnet.
  bool get isWindowsHotspot => ip.startsWith('192.168.137.');

  String get label => '$ip  ($interfaceName)';
}

/// Lower is better: hotspot first, then typical home/school private ranges.
int _rank(LanAddress a) {
  if (a.isWindowsHotspot) return 0;
  if (a.ip.startsWith('192.168.')) return 1;
  if (a.ip.startsWith('10.')) return 2;
  final parts = a.ip.split('.');
  final second = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
  if (a.ip.startsWith('172.') && second >= 16 && second <= 31) return 3;
  return 4;
}

/// Orders candidate addresses, dropping loopback and link-local ones and
/// typical virtual adapters (VirtualBox, Hyper-V, WSL, VMware, Docker).
List<LanAddress> sortLanAddresses(Iterable<LanAddress> all) {
  final virtual = RegExp(
    r'virtualbox|vmware|vethernet|hyper-v|wsl|docker|loopback',
    caseSensitive: false,
  );
  final list =
      all
          .where(
            (a) => !a.ip.startsWith('127.') && !a.ip.startsWith('169.254.'),
          )
          .toList()
        ..sort((a, b) {
          final va = virtual.hasMatch(a.interfaceName) ? 1 : 0;
          final vb = virtual.hasMatch(b.interfaceName) ? 1 : 0;
          if (va != vb) return va - vb;
          return _rank(a).compareTo(_rank(b));
        });
  return list;
}

/// IPv4 addresses of this machine, best candidate first.
Future<List<LanAddress>> listLanAddresses() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );
  return sortLanAddresses([
    for (final i in interfaces)
      for (final a in i.addresses)
        LanAddress(interfaceName: i.name, ip: a.address),
  ]);
}
