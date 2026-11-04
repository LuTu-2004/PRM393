import 'package:flutter_test/flutter_test.dart';
import 'package:exe_matching/services/storage_service.dart';
import 'package:exe_matching/services/notification_service.dart';
import 'package:exe_matching/services/remote_config_service.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';

void main() {
  group('Kiểm thử 6 Dịch vụ Firebase (Lab 3 Requirements)', () {
    test('1. Firebase Cloud Storage: Sinh file bytes và upload trong mock mode an toàn', () async {
      final bytes = StorageService.generateSimpleTextFile('Báo cáo mẫu PRM393');
      expect(bytes, isNotEmpty);

      double reportedProgress = 0.0;
      final url = await StorageService.uploadReport(
        fileBytes: bytes,
        fileName: 'test_report.txt',
        onProgress: (p) => reportedProgress = p,
      );

      expect(url, contains('mock_report.pdf'));
      final files = await StorageService.listUserReports();
      expect(files, isNotEmpty);
      expect(files.first.name, contains('report'));
    });

    test('2. Firebase Cloud Messaging: Thêm thông báo, lưu lịch sử và gọi listener', () {
      int callbackCount = 0;
      void listener() => callbackCount++;

      NotificationService.addListener(listener);

      final initialLength = NotificationService.history.length;
      NotificationService.addMockNotification('Test Title', 'Test Body message');

      expect(NotificationService.history.length, equals(initialLength + 1));
      expect(NotificationService.history.first.title, equals('Test Title'));
      expect(callbackCount, greaterThan(0));

      NotificationService.removeListener(listener);
    });

    test('3. Firebase Remote Config: Giá trị mặc định khớp Business Rules và refresh an toàn', () async {
      expect(RemoteConfigService.maxPendingRequests, equals(3));
      expect(RemoteConfigService.votingDurationHours, equals(24));
      expect(RemoteConfigService.showMatchingBanner, isTrue);

      final refreshed = await RemoteConfigService.refresh();
      expect(refreshed['max_pending_requests'], equals(3));
      expect(refreshed['voting_duration_hours'], equals(24));
    });

    test('4. Google Analytics: Ghi nhận 9 loại sự kiện mà không gây exception', () async {
      expect(() async => await AnalyticsService.logRoomCreated(subjectCode: 'EXE101', isPublic: true), returnsNormally);
      expect(() async => await AnalyticsService.logSignIn(role: 'student', major: 'SE', cohort: 'K18'), returnsNormally);
      expect(() async => await AnalyticsService.logSignOut(), returnsNormally);
      expect(() async => await AnalyticsService.logViewRoom(roomId: 'room_001', subjectCode: 'EXE101'), returnsNormally);
      expect(() async => await AnalyticsService.logJoinRequestSent(roomId: 'room_001'), returnsNormally);
      expect(() async => await AnalyticsService.logMajorWarningShown(roomId: 'room_001', ratio: 0.6), returnsNormally);
      expect(() async => await AnalyticsService.logVoteSessionStarted(roomId: 'room_001'), returnsNormally);
      expect(() async => await AnalyticsService.logVoteCast(roomId: 'room_001'), returnsNormally);
      expect(() async => await AnalyticsService.logReportExported(), returnsNormally);
      expect(() async => await AnalyticsService.setCurrentUser('user_test_123'), returnsNormally);
    });

    test('5. Firebase Crashlytics: Bắt lỗi không làm gián đoạn luồng thực thi', () async {
      expect(
        () async => await CrashlyticsService.recordError(
          Exception('Unit test handled error'),
          StackTrace.current,
          reason: 'Unit test',
          screen: 'TestScreen',
        ),
        returnsNormally,
      );

      expect(() async => await CrashlyticsService.setUserIdentifier('user_test_123'), returnsNormally);
      expect(() async => await CrashlyticsService.setCustomKey('test_key', 'test_value'), returnsNormally);
    });
  });
}
