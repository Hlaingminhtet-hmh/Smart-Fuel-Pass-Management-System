class AppUser {
  final int id;
  final String name;
  final String nationalId;
  final String phone;

  const AppUser({
    required this.id,
    required this.name,
    required this.nationalId,
    required this.phone,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: int.tryParse('${j['id'] ?? 0}') ?? 0,
    name: '${j['name'] ?? ''}',
    nationalId: '${j['national_id'] ?? ''}',
    phone: '${j['phone'] ?? ''}',
  );
}
