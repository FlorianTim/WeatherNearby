/// A runtime permission as the app sees it.
///
/// The four states are deliberately distinct. Collapsing
/// [permanentlyDenied] into [denied] — the single most common shortcut —
/// leaves the user with no way back: the system dialog will not appear
/// again, so an app that keeps calling `request()` looks broken.
enum PermissionState {
  /// Never asked. The system dialog has not been shown yet.
  notRequested,

  /// Usable.
  granted,

  /// Refused this time. Asking again later is allowed.
  denied,

  /// Refused for good (or blocked by policy). Only the system settings can
  /// change this — `request()` returns immediately without a dialog.
  permanentlyDenied;

  bool get isGranted => this == PermissionState.granted;

  /// Whether showing the system dialog can still produce a decision.
  bool get canRequest =>
      this == PermissionState.notRequested || this == PermissionState.denied;
}

/// One runtime permission behind an app-owned interface.
///
/// One implementation per permission (contacts, calendar, notifications,
/// location, camera, …) — the architecture is identical, only the plugin
/// call and the copy differ. See
/// `docs/architecture/patterns/permissions.md` for wiring a concrete
/// implementation, and `docs/architecture/contracts/04-permissions.md` for
/// the rules this interface exists to make keepable.
abstract interface class PermissionGateway {
  /// Current state **as the system reports it**.
  ///
  /// Must actually query the platform. A cached answer goes stale the moment
  /// the user revokes the permission in the system settings, and the app
  /// would only notice on the next write attempt.
  Future<PermissionState> status();

  /// Shows the system dialog. Call **only** after an in-app rationale.
  Future<PermissionState> request();

  /// Opens the system settings page for this app, so a
  /// [PermissionState.permanentlyDenied] can be undone.
  Future<void> openAppSettings();
}
