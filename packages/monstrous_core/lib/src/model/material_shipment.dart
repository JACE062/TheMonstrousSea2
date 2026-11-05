enum TradeMaterial {
  seaGlass('Sea Glass'),
  depthWroughtIron('Depth-Wrought Iron');

  const TradeMaterial(this.displayName);
  final String displayName;
}

/// One merchant's finite allocation, independent of its consumable selection.
/// An empty instance is a rolled empty shipment, not an uninitialized shop.
class MaterialShipment {
  MaterialShipment({
    required this.id,
    this.seaGlass = 0,
    this.depthWroughtIron = 0,
  });
  factory MaterialShipment.fromJson(Map<String, dynamic> json) =>
      MaterialShipment(
        id: json['id'] as String,
        seaGlass: json['seaGlass'] as int? ?? 0,
        depthWroughtIron: json['depthWroughtIron'] as int? ?? 0,
      );
  final String id;
  int seaGlass, depthWroughtIron;
  int quantity(TradeMaterial material) => switch (material) {
    TradeMaterial.seaGlass => seaGlass,
    TradeMaterial.depthWroughtIron => depthWroughtIron,
  };
  void remove(TradeMaterial material, int quantity) {
    switch (material) {
      case TradeMaterial.seaGlass:
        seaGlass -= quantity;
      case TradeMaterial.depthWroughtIron:
        depthWroughtIron -= quantity;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seaGlass': seaGlass,
    'depthWroughtIron': depthWroughtIron,
  };
}
