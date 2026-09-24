import 'package:diem_danh/services/checkin_server/lan_addresses.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'hotspot first, virtual adapters last, loopback and link-local dropped',
    () {
      final sorted = sortLanAddresses(const [
        LanAddress(interfaceName: 'vEthernet (WSL)', ip: '172.20.0.1'),
        LanAddress(interfaceName: 'Wi-Fi', ip: '10.10.5.23'),
        LanAddress(interfaceName: 'Ethernet', ip: '169.254.3.4'),
        LanAddress(
          interfaceName: 'Local Area Connection* 10',
          ip: '192.168.137.1',
        ),
        LanAddress(interfaceName: 'Loopback', ip: '127.0.0.1'),
        LanAddress(interfaceName: 'Ethernet 2', ip: '192.168.1.20'),
      ]);
      expect(sorted.map((a) => a.ip), [
        '192.168.137.1',
        '192.168.1.20',
        '10.10.5.23',
        '172.20.0.1',
      ]);
      expect(sorted.first.isWindowsHotspot, isTrue);
    },
  );
}
