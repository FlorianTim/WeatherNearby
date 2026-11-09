import 'package:mobile_app/core/permissions/permission_gateway.dart';

/// Scriptable [PermissionGateway] for tests.
///
/// Covers all four states plus the two things that are easy to get wrong and
/// impossible to observe on a device in CI:
///
///  - how often `request()` was called (asking again after a permanent
///    denial is a defect, not a retry),
///  - whether the system settings were opened.
///
/// It also records the call order, so a test can prove that the rationale
/// came *before* the system dialog rather than after it.
class FakePermissionGateway implements PermissionGateway {
  FakePermissionGateway({
    this.state = PermissionState.notRequested,
    this.grantOnRequest = true,
  });

  /// Current state, as `status()` reports it. Mutable so a test can simulate
  /// the user changing it in the system settings.
  PermissionState state;

  /// What the simulated user answers in the system dialog.
  bool grantOnRequest;

  /// Every call, in order: `status`, `request`, `openAppSettings`.
  final List<String> calls = [];

  int get requestCount => calls.where((c) => c == 'request').length;
  bool get openedAppSettings => calls.contains('openAppSettings');

  @override
  Future<PermissionState> status() async {
    calls.add('status');
    return state;
  }

  @override
  Future<PermissionState> request() async {
    calls.add('request');
    if (state == PermissionState.permanentlyDenied) {
      // Mirrors the platform: no dialog appears, the answer is immediate.
      return state;
    }
    state = grantOnRequest ? PermissionState.granted : PermissionState.denied;
    return state;
  }

  @override
  Future<void> openAppSettings() async {
    calls.add('openAppSettings');
  }
}
