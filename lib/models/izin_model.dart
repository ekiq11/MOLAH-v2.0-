class IzinModel {
  final String tanggal;
  final String waktuIzin;
  final String nisn;
  final String nama;
  final String kelasAsrama;
  final String tanggalIzin;
  final String batasIzin;
  final String alasanIzin;
  final String tanggalBalik;
  final String waktuBalik;
  final String status;
  final String keterangan;

  IzinModel({
    required this.tanggal,
    required this.waktuIzin,
    required this.nisn,
    required this.nama,
    required this.kelasAsrama,
    required this.tanggalIzin,
    required this.batasIzin,
    required this.alasanIzin,
    required this.tanggalBalik,
    required this.waktuBalik,
    required this.status,
    required this.keterangan,
  });

  factory IzinModel.fromCsv(List<dynamic> row) {
    return IzinModel(
      tanggal: row.isNotEmpty ? row[0].toString().trim() : '',
      waktuIzin: row.length > 1 ? row[1].toString().trim() : '',
      nisn: row.length > 2 ? row[2].toString().trim() : '',
      nama: row.length > 3 ? row[3].toString().trim() : '',
      kelasAsrama: row.length > 4 ? row[4].toString().trim() : '',
      tanggalIzin: row.length > 5 ? row[5].toString().trim() : '',
      batasIzin: row.length > 6 ? row[6].toString().trim() : '',
      alasanIzin: row.length > 7 ? row[7].toString().trim() : '',
      tanggalBalik: row.length > 8 ? row[8].toString().trim() : '',
      waktuBalik: row.length > 9 ? row[9].toString().trim() : '',
      status: row.length > 10 ? row[10].toString().trim() : '',
      keterangan: row.length > 11 ? row[11].toString().trim() : '',
    );
  }

  // Backward compatibility dengan UI lama
  String get qrCodeUrl => nisn.isNotEmpty ? 'https://quickchart.io/chart?chs=150x150&cht=qr&chl=$nisn' : '';
  String get alasanAtauPenerima => alasanIzin;
  String get timestamp => '$tanggalIzin $waktuIzin';
  String get batasWaktuAtauWaktuIzin => batasIzin;

  bool get isSedangIzin => status.toLowerCase() != 'sudah balik ke pondok' && status.toLowerCase() != 'kembali';
  bool get isBalikPondok => !isSedangIzin;
  String get tipeIzin => alasanIzin;
  String get pemberiIzinAtauStatusKepulangan => keterangan;
}
