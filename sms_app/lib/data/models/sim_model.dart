/// Represents a SIM card detected on the device.
class SimModel {
  final String id;
  final String carrierName;
  final String number;
  final int slotIndex;

  SimModel({
    required this.id,
    required this.carrierName,
    required this.number,
    required this.slotIndex,
  });

  @override
  String toString() => 'SIM $slotIndex: $carrierName ($number)';
}
