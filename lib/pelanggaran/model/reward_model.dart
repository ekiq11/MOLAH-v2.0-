class RewardPelanggaranData {
  final String id;
  final String jenisPemberian;
  final String kodeEtika;
  final String jenisEtika;
  final String jumlahPelanggaran;
  final String jumlahReward;
  final String nisn;
  final String namaSantri;
  final String kelasAsrama;
  final String hariTanggal;
  final String waktu;
  final String tempatKejadian;
  final String rincianKejadian;
  final String ustadzGuru;

  RewardPelanggaranData({
    required this.id,
    required this.jenisPemberian,
    required this.kodeEtika,
    required this.jenisEtika,
    required this.jumlahPelanggaran,
    required this.jumlahReward,
    required this.nisn,
    required this.namaSantri,
    required this.kelasAsrama,
    required this.hariTanggal,
    required this.waktu,
    required this.tempatKejadian,
    required this.rincianKejadian,
    required this.ustadzGuru,
  });

  factory RewardPelanggaranData.fromCsvRow(List<dynamic> row) {
    return RewardPelanggaranData(
      id: row.isNotEmpty ? row[0].toString().trim() : '',
      jenisPemberian: row.length > 1 ? row[1].toString().trim() : '',
      kodeEtika: row.length > 2 ? row[2].toString().trim() : '',
      jenisEtika: row.length > 3 ? row[3].toString().trim() : '',
      jumlahPelanggaran: row.length > 4 ? row[4].toString().trim() : '',
      jumlahReward: row.length > 5 ? row[5].toString().trim() : '',
      nisn: row.length > 6 ? row[6].toString().replaceAll("'", "").trim() : '',
      namaSantri: row.length > 7 ? row[7].toString().trim() : '',
      kelasAsrama: row.length > 8 ? row[8].toString().trim() : '',
      hariTanggal: row.length > 9 ? row[9].toString().trim() : '',
      waktu: row.length > 10 ? row[10].toString().trim() : '',
      tempatKejadian: row.length > 11 ? row[11].toString().trim() : '',
      rincianKejadian: row.length > 12 ? row[12].toString().trim() : '',
      ustadzGuru: row.length > 13 ? row[13].toString().trim() : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jenisPemberian': jenisPemberian,
      'kodeEtika': kodeEtika,
      'jenisEtika': jenisEtika,
      'jumlahPelanggaran': jumlahPelanggaran,
      'jumlahReward': jumlahReward,
      'nisn': nisn,
      'namaSantri': namaSantri,
      'kelasAsrama': kelasAsrama,
      'hariTanggal': hariTanggal,
      'waktu': waktu,
      'tempatKejadian': tempatKejadian,
      'rincianKejadian': rincianKejadian,
      'ustadzGuru': ustadzGuru,
    };
  }

  factory RewardPelanggaranData.fromJson(Map<String, dynamic> json) {
    return RewardPelanggaranData(
      id: json['id'] ?? '',
      jenisPemberian: json['jenisPemberian'] ?? '',
      kodeEtika: json['kodeEtika'] ?? '',
      jenisEtika: json['jenisEtika'] ?? '',
      jumlahPelanggaran: json['jumlahPelanggaran'] ?? '',
      jumlahReward: json['jumlahReward'] ?? '',
      nisn: json['nisn'] ?? '',
      namaSantri: json['namaSantri'] ?? '',
      kelasAsrama: json['kelasAsrama'] ?? '',
      hariTanggal: json['hariTanggal'] ?? '',
      waktu: json['waktu'] ?? '',
      tempatKejadian: json['tempatKejadian'] ?? '',
      rincianKejadian: json['rincianKejadian'] ?? '',
      ustadzGuru: json['ustadzGuru'] ?? '',
    );
  }

  bool get isReward => jenisPemberian.toUpperCase().contains('REWARD');
  bool get isPelanggaran => jenisPemberian.toUpperCase().contains('PELANGGARAN');
  
  // Get numeric value for calculations
  int get rewardPoin {
    try {
      return int.parse(jumlahReward.replaceAll(RegExp(r'[^0-9]'), ''));
    } catch (e) {
      return 0;
    }
  }
  
  int get pelanggaranPoin {
    try {
      return int.parse(jumlahPelanggaran.replaceAll(RegExp(r'[^0-9]'), ''));
    } catch (e) {
      return 0;
    }
  }
}

// Class untuk menghitung total poin
class PoinStatistik {
  final int totalReward;
  final int totalPelanggaran;
  final int selisih;
  final int jumlahReward;
  final int jumlahPelanggaran;

  PoinStatistik({
    required this.totalReward,
    required this.totalPelanggaran,
    required this.selisih,
    required this.jumlahReward,
    required this.jumlahPelanggaran,
  });

  static PoinStatistik calculate(List<RewardPelanggaranData> data) {
    int totalReward = 0;
    int totalPelanggaran = 0;
    int jumlahReward = 0;
    int jumlahPelanggaran = 0;

    for (var item in data) {
      if (item.isReward) {
        totalReward += item.rewardPoin;
        jumlahReward++;
      } else if (item.isPelanggaran) {
        totalPelanggaran += item.pelanggaranPoin;
        jumlahPelanggaran++;
      }
    }

    return PoinStatistik(
      totalReward: totalReward,
      totalPelanggaran: totalPelanggaran,
      selisih: totalReward - totalPelanggaran,
      jumlahReward: jumlahReward,
      jumlahPelanggaran: jumlahPelanggaran,
    );
  }
}