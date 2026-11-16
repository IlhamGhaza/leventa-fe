import '../../../core/utils/json.dart';

class UserRole {
  const UserRole._();
  static const sales = 'sales';
  static const admin = 'admin';

  static String label(String role) => switch (role) {
    sales => 'Marketing',
    admin => 'Admin',
    _ => role,
  };
}

/// User from `/auth/me`, login response, or Admin user endpoints.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.phone,
    this.whatsappNumber,
    this.avatar,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String? phone;
  final String? whatsappNumber;
  final String? avatar;
  final DateTime? createdAt;

  bool get isActive => status == 'active';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final s = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return s.isEmpty ? '?' : s;
  }

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: strOr(j['id']),
    name: strOr(j['name']),
    email: strOr(j['email']),
    role: strOr(j['role']),
    status: strOr(j['status'], 'active'),
    phone: str(j['phone']),
    whatsappNumber: str(j['whatsapp_number']),
    avatar: str(j['avatar']),
    createdAt: date(j['created_at']),
  );
}

/// Which shell the app shows. Derived only from the verified backend role.
enum AppShell { guest, marketing, admin, unsupported }

AppShell shellFor(AppUser? user) {
  if (user == null) return AppShell.guest;
  switch (user.role) {
    case UserRole.sales:
      return AppShell.marketing;
    case UserRole.admin:
      return AppShell.admin;
    default:
      // Retired `customer` / `staff` and unknown values: never guess.
      return AppShell.unsupported;
  }
}
