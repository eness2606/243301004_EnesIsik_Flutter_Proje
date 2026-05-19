class RoomModel {
  final String id;
  final String number;
  final int floor;
  final int capacity;
  final int currentOccupancy;
  final String type; // '2 Kişilik' | '3 Kişilik'

  RoomModel({
    required this.id,
    required this.number,
    required this.floor,
    required this.capacity,
    required this.currentOccupancy,
    required this.type,
  });

  int get availableSpots => capacity - currentOccupancy;
  bool get isFull => availableSpots <= 0;

  factory RoomModel.fromMap(Map<String, dynamic> map, String id) {
    return RoomModel(
      id: id,
      number: map['number'] ?? '',
      floor: map['floor'] ?? 1,
      capacity: map['capacity'] ?? 0,
      currentOccupancy: map['currentOccupancy'] ?? 0,
      type: map['type'] ?? '2 Kişilik',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'floor': floor,
      'capacity': capacity,
      'currentOccupancy': currentOccupancy,
      'type': type,
    };
  }
}
