import '../models/models.dart';

class AppData {
  static const List<PropItem> props = [
    PropItem(
      id: "p1", name: "Rumah Modern 2 Lantai di Bintaro", type: "Rumah",
      price: 1850000000, priceType: "jual", unit: "",
      loc: "Bintaro, Tangerang Selatan", beds: 4, baths: 3, build: 180, land: 220,
      status: "available", featured: true,
      img: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&h=520&fit=crop&auto=format",
      desc: "Rumah modern 2 lantai dengan desain kontemporer di kawasan Bintaro yang strategis. Dekat dengan pusat perbelanjaan, sekolah internasional, dan akses tol JORR.",
    ),
    PropItem(
      id: "p2", name: "Apartemen 3 Kamar Jakarta Selatan", type: "Apartemen",
      price: 15000000, priceType: "sewa", unit: "/ bulan",
      loc: "Kebayoran Baru, Jakarta Selatan", beds: 3, baths: 2, build: 110, land: 0,
      status: "available", featured: true,
      img: "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&h=520&fit=crop&auto=format",
      desc: "Apartemen premium dengan view kota Jakarta yang memukau. Fasilitas kolam renang, gym, concierge, dan parkir luas. Akses mudah ke MRT Lebak Bulus.",
    ),
    PropItem(
      id: "p3", name: "Villa Mewah Kolam Renang di Dago Bandung", type: "Villa",
      price: 3200000000, priceType: "jual", unit: "",
      loc: "Dago, Bandung", beds: 5, baths: 4, build: 350, land: 500,
      status: "available", featured: true,
      img: "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&h=520&fit=crop&auto=format",
      desc: "Villa mewah eksklusif di perbukitan Dago. Kolam renang infinity, taman privat, dan pemandangan kota Bandung yang menakjubkan dari ketinggian.",
    ),
    PropItem(
      id: "p4", name: "Ruko Strategis 3 Lantai di Antapani", type: "Ruko",
      price: 2500000000, priceType: "jual", unit: "",
      loc: "Antapani, Bandung", beds: 0, baths: 2, build: 240, land: 120,
      status: "available", featured: false,
      img: "https://images.unsplash.com/photo-1486325212027-8081e485255e?w=800&h=520&fit=crop&auto=format",
      desc: "Ruko 3 lantai di lokasi strategis kawasan bisnis Antapani. Cocok untuk kuliner, apotek, kantor, atau toko retail. Parkir luas dan akses mudah.",
    ),
    PropItem(
      id: "p5", name: "Gudang Industri Kawasan Cikarang", type: "Gudang",
      price: 4500000000, priceType: "jual", unit: "",
      loc: "Cikarang, Bekasi", beds: 0, baths: 4, build: 800, land: 1200,
      status: "available", featured: false,
      img: "https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&h=520&fit=crop&auto=format",
      desc: "Gudang industri di kawasan Cikarang, Bekasi. Akses mudah ke tol Jakarta-Cikampek dan dekat kawasan industri besar.",
    ),
    PropItem(
      id: "p6", name: "Rumah Minimalis Modern di Beji Depok", type: "Rumah",
      price: 890000000, priceType: "jual", unit: "",
      loc: "Beji, Depok", beds: 3, baths: 2, build: 120, land: 150,
      status: "sold", featured: false,
      img: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&h=520&fit=crop&auto=format",
      desc: "Rumah minimalis modern 2 lantai di kawasan tenang Beji, Depok. Dekat Universitas Indonesia dan stasiun commuter line Pondok Cina.",
    ),
  ];

  static const List<LeadItem> leads = [
    LeadItem(id: "l1", customer: "Budi Santoso", phone: "+62 812 3456 7890", email: "budi.santoso@email.com", prop: "Rumah Modern 2 Lantai di Bintaro", status: "negotiation", budget: 2000000000, lastContact: "2 jam lalu", nextFU: "Besok, 10:00", date: "5 Agu 2026"),
    LeadItem(id: "l2", customer: "Dewi Rahayu", phone: "+62 821 9876 5432", email: "dewi.rahayu@email.com", prop: "Apartemen 3 Kamar Jakarta Selatan", status: "survey", budget: 200000000, lastContact: "Kemarin", nextFU: "14 Agu, 14:00", date: "1 Agu 2026"),
    LeadItem(id: "l3", customer: "Ahmad Fauzi", phone: "+62 813 5678 9012", email: "ahmad.fauzi@email.com", prop: "Villa Mewah di Dago Bandung", status: "qualified", budget: 3500000000, lastContact: "3 hari lalu", nextFU: "16 Agu, 09:00", date: "28 Jul 2026"),
    LeadItem(id: "l4", customer: "Siti Nurhaliza", phone: "+62 857 2345 6789", email: "siti.n@email.com", prop: "Ruko Antapani Bandung", status: "contacted", budget: 3000000000, lastContact: "4 hari lalu", nextFU: "17 Agu 2026", date: "20 Jul 2026"),
    LeadItem(id: "l5", customer: "Hendra Wijaya", phone: "+62 878 3456 7890", email: "hendra.w@email.com", prop: "Gudang Industri Cikarang", status: "new", budget: 5000000000, lastContact: "Baru masuk", nextFU: "Segera", date: "14 Agu 2026"),
  ];

  static const List<ChartData> chartData = [
    ChartData("Mar", 3), ChartData("Apr", 5), ChartData("Mei", 4),
    ChartData("Jun", 7), ChartData("Jul", 6), ChartData("Agu", 8),
  ];

  static const List<PipelineItem> pipeline = [
    PipelineItem("Baru", 5, "FF3B82F6"),
    PipelineItem("Dihubungi", 8, "FF8B5CF6"),
    PipelineItem("Qualified", 6, "FF06B6D4"),
    PipelineItem("Survey", 4, "FFF59E0B"),
    PipelineItem("Nego", 3, "FFF97316"),
    PipelineItem("Won", 9, "FF22C55E"),
  ];

  static const List<NotifItem> notifs = [
    NotifItem(id: "n1", title: "Lead baru ditugaskan", body: "Hendra Wijaya tertarik Gudang Cikarang", time: "5 mnt lalu", read: false),
    NotifItem(id: "n2", title: "Survey dikonfirmasi", body: "Survey dengan Dewi Rahayu, hari ini 14:00", time: "1 jam lalu", read: false),
    NotifItem(id: "n3", title: "Status lead diperbarui", body: "Ahmad Fauzi masuk tahap Negosiasi", time: "3 jam lalu", read: true),
    NotifItem(id: "n4", title: "Deal berhasil dicatat", body: "Rumah Minimalis Depok — TERJUAL", time: "Kemarin", read: true),
    NotifItem(id: "n5", title: "Properti baru tersedia", body: "Apartemen baru di Jakarta Pusat ditambahkan", time: "2 hari lalu", read: true),
  ];

  static const List<InquiryItem> inquiries = [
    InquiryItem(id: "i1", prop: "Rumah Modern 2 Lantai di Bintaro", sales: "Andi Pratama", date: "10 Agu 2026", status: "negotiation", lastUpdate: "2 hari lalu"),
    InquiryItem(id: "i2", prop: "Villa Mewah Dago Bandung", sales: "Belum ditugaskan", date: "8 Agu 2026", status: "new", lastUpdate: "6 hari lalu"),
  ];

  static const List<TimelineItem> timeline = [
    TimelineItem(date: "10 Agu 2026, 09:00", event: "Inquiry diterima", detail: "Customer mengirim inquiry via aplikasi", type: "inquiry"),
    TimelineItem(date: "10 Agu 2026, 11:30", event: "Lead ditugaskan", detail: "Lead ditugaskan ke Andi Pratama (Sales)", type: "assign"),
    TimelineItem(date: "10 Agu 2026, 14:00", event: "Sales menghubungi", detail: "Telepon pertama — customer sangat tertarik", type: "call"),
    TimelineItem(date: "11 Agu 2026, 10:00", event: "Survey dijadwalkan", detail: "Survey property Sabtu, 15 Agu 2026 pukul 10:00", type: "schedule"),
    TimelineItem(date: "13 Agu 2026, 12:00", event: "Survey selesai", detail: "Customer puas, masuk tahap negosiasi harga", type: "complete"),
  ];

  static const List<ScheduleItem> schedules = [
    ScheduleItem(id: "s1", customer: "Dewi Rahayu", property: "Apartemen Jakarta Selatan", time: "14:00", status: "today", type: "Survey"),
    ScheduleItem(id: "s2", customer: "Ahmad Fauzi", property: "Villa Dago Bandung", time: "16:30", status: "today", type: "Meeting"),
    ScheduleItem(id: "s3", customer: "Budi Santoso", property: "Rumah 2 Lantai Bintaro", time: "10:00, Sabtu 15 Agu", status: "upcoming", type: "Negosiasi"),
    ScheduleItem(id: "s4", customer: "Siti Nurhaliza", property: "Ruko Antapani Bandung", time: "13:00, Senin 17 Agu", status: "upcoming", type: "Survey"),
  ];
}
