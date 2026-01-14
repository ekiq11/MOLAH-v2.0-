// models/doa_model.dart
class Doa {
  final String idDoa;
  final String nama;
  final String lafal;
  final String transliterasi;
  final String arti;
  final String riwayat;
  final String? keterangan;
  final List<String> kataKunci;

  Doa({
    required this.idDoa,
    required this.nama,
    required this.lafal,
    required this.transliterasi,
    required this.arti,
    required this.riwayat,
    this.keterangan,
    required this.kataKunci,
  });

  factory Doa.fromJson(Map<String, dynamic> json) {
    return Doa(
      idDoa: json['id_doa'].toString(),
      nama: json['nama'] as String,
      lafal: json['lafal'] as String,
      transliterasi: json['transliterasi'] as String,
      arti: json['arti'] as String,
      riwayat: json['riwayat'] as String,
      keterangan: json['keterangan'] as String?,
      kataKunci: (json['kata_kunci'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_doa': idDoa,
      'nama': nama,
      'lafal': lafal,
      'transliterasi': transliterasi,
      'arti': arti,
      'riwayat': riwayat,
      'keterangan': keterangan,
      'kata_kunci': kataKunci,
    };
  }
}