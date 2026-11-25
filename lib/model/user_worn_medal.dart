/// Shared user decoration data, preserved in the login/profile cache.
class UserWornMedal {
  const UserWornMedal({
    required this.id,
    required this.icon,
    this.sortingOrder = 0,
  });
  final String id, icon;
  final int sortingOrder;
  factory UserWornMedal.fromJson(Map<String, dynamic> json) => UserWornMedal(
    id: '${json['id'] ?? ''}',
    icon: '${json['icon'] ?? ''}',
    sortingOrder: int.tryParse('${json['sortingOrder']}') ?? 0,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'icon': icon,
    'sortingOrder': sortingOrder,
  };
}
