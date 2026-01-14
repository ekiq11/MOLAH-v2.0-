// model/model_dzikir.dart
class Dzikir {
  final String idDzikir;
  final String nama;
  final String lafal;
  final String transliterasi;
  final String arti;
  final String riwayat;
  final String keterangan;
  final String? footnote;
  final String repeat;
  final String type; // 'pagi', 'petang', or 'both'

  Dzikir({
    required this.idDzikir,
    required this.nama,
    required this.lafal,
    required this.transliterasi,
    required this.arti,
    required this.riwayat,
    required this.keterangan,
    this.footnote,
    required this.repeat,
    required this.type,
  });

  factory Dzikir.fromJson(Map<String, dynamic> json) {
    return Dzikir(
      idDzikir: json['id_dzikir'] ?? '',
      nama: json['nama'] ?? '',
      lafal: json['lafal'] ?? '',
      transliterasi: json['transliterasi'] ?? '',
      arti: json['arti'] ?? '',
      riwayat: json['riwayat'] ?? '',
      keterangan: json['keterangan'] ?? '',
      footnote: json['footnote'],
      repeat: json['repeat'] ?? '1',
      type: json['type'] ?? 'both',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_dzikir': idDzikir,
      'nama': nama,
      'lafal': lafal,
      'transliterasi': transliterasi,
      'arti': arti,
      'riwayat': riwayat,
      'keterangan': keterangan,
      'footnote': footnote,
      'repeat': repeat,
      'type': type,
    };
  }

  // Helper method to check if this dzikir should be shown in morning
  bool get isForMorning => type == 'pagi' || type == 'both';

  // Helper method to check if this dzikir should be shown in evening
  bool get isForEvening => type == 'petang' || type == 'both';

  // Get appropriate time display
  String get timeDisplay {
    switch (type) {
      case 'pagi':
        return 'Pagi';
      case 'petang':
        return 'Sore/Petang';
      case 'both':
        return 'Pagi & Sore';
      default:
        return 'Pagi & Sore';
    }
  }
}