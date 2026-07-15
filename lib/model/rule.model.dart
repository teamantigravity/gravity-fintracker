class Rule {
  int? id;
  String name;
  bool enabled;
  int? sourceAccountId;
  int? sourceCategoryId;
  String? type;
  double? minAmount;
  double? maxAmount;
  double percentage;
  int targetAccountId;
  int targetCategoryId;
  String? targetType;
  String description;

  Rule({
    this.id,
    required this.name,
    this.enabled = true,
    this.sourceAccountId,
    this.sourceCategoryId,
    this.type,
    this.minAmount,
    this.maxAmount,
    this.percentage = 0.0,
    required this.targetAccountId,
    required this.targetCategoryId,
    this.targetType,
    this.description = '',
  });

  factory Rule.fromJson(Map<String, dynamic> data) => Rule(
    id: data["id"],
    name: data["name"] ?? '',
    enabled: data["enabled"] == 1 || data["enabled"] == true,
    sourceAccountId: data["sourceAccount"],
    sourceCategoryId: data["sourceCategory"],
    type: data["type"],
    minAmount: (data["minAmount"] as num?)?.toDouble(),
    maxAmount: (data["maxAmount"] as num?)?.toDouble(),
    percentage: (data["percentage"] as num?)?.toDouble() ?? 0.0,
    targetAccountId: data["targetAccount"],
    targetCategoryId: data["targetCategory"],
    targetType: data["targetType"],
    description: data["description"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "enabled": enabled ? 1 : 0,
    "sourceAccount": sourceAccountId,
    "sourceCategory": sourceCategoryId,
    "type": type,
    "minAmount": minAmount,
    "maxAmount": maxAmount,
    "percentage": percentage,
    "targetAccount": targetAccountId,
    "targetCategory": targetCategoryId,
    "targetType": targetType,
    "description": description,
  };
}
