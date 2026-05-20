import 'dart:math';

class QuizQuestion {
  final String question;
  final List<String> options; // Index 0=A, 1=B, 2=C, 3=D
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class QuizService {
  final List<QuizQuestion> _localQuestions = [
    // --- SEJARAH & BUDAYA ---
    QuizQuestion(
      question: "Apa warna bendera negara Indonesia?",
      options: ["Merah Putih", "Biru Putih", "Merah Kuning", "Hijau Putih"],
      correctIndex: 0,
      explanation: "Bendera Indonesia adalah Sang Saka Merah Putih.",
    ),
    QuizQuestion(
      question: "Siapakah Presiden pertama Republik Indonesia?",
      options: ["Soeharto", "Soekarno", "B.J. Habibie", "Abdurrahman Wahid"],
      correctIndex: 1,
      explanation: "Ir. Soekarno adalah proklamator dan presiden pertama Indonesia.",
    ),
    QuizQuestion(
      question: "Candi Borobudur terletak di provinsi mana?",
      options: ["Jawa Barat", "Jawa Timur", "Jawa Tengah", "Yogyakarta"],
      correctIndex: 2,
      explanation: "Borobudur adalah candi Buddha terbesar yang terletak di Magelang, Jawa Tengah.",
    ),
    QuizQuestion(
      question: "Rumah adat Minangkabau disebut rumah?",
      options: ["Joglo", "Gadang", "Honai", "Limas"],
      correctIndex: 1,
      explanation: "Rumah Gadang adalah rumah tradisional dari Sumatera Barat.",
    ),

    // --- SAINS & ALAM ---
    QuizQuestion(
      question: "Hewan apa yang dikenal sebagai Raja Hutan?",
      options: ["Gajah", "Harimau", "Singa", "Serigala"],
      correctIndex: 2,
      explanation: "Singa dijuluki sebagai raja hutan karena kekuatannya.",
    ),
    QuizQuestion(
      question: "Planet manakah yang dikenal sebagai Planet Merah?",
      options: ["Mars", "Jupiter", "Saturnus", "Venus"],
      correctIndex: 0,
      explanation: "Mars terlihat merah karena besi oksida di permukaannya.",
    ),
    QuizQuestion(
      question: "Berapakah jumlah kaki pada seekor laba-laba?",
      options: ["Enam", "Sepuluh", "Delapan", "Dua belas"],
      correctIndex: 2,
      explanation: "Semua jenis laba-laba memiliki delapan kaki.",
    ),
    QuizQuestion(
      question: "Logam apa yang cair pada suhu ruangan?",
      options: ["Emas", "Perak", "Besi", "Raksa"],
      correctIndex: 3,
      explanation: "Raksa atau Merkuri adalah logam yang berbentuk cair pada suhu normal.",
    ),

    // --- GEOGRAFI ---
    QuizQuestion(
      question: "Ibukota negara Jepang adalah?",
      options: ["Seoul", "Beijing", "Tokyo", "Bangkok"],
      correctIndex: 2,
      explanation: "Tokyo adalah ibukota sekaligus pusat ekonomi negara Jepang.",
    ),
    QuizQuestion(
      question: "Gunung tertinggi di dunia adalah gunung?",
      options: ["Semeru", "Everest", "Kilimanjaro", "Fuji"],
      correctIndex: 1,
      explanation: "Gunung Everest terletak di pegunungan Himalaya.",
    ),
    QuizQuestion(
      question: "Benua terkecil di dunia adalah?",
      options: ["Asia", "Eropa", "Afrika", "Australia"],
      correctIndex: 3,
      explanation: "Australia adalah benua terkecil sekaligus sebuah negara.",
    ),
    QuizQuestion(
      question: "Samudra terluas di bumi adalah?",
      options: ["Hindia", "Atlantik", "Pasifik", "Arktik"],
      correctIndex: 2,
      explanation: "Samudra Pasifik mencakup sepertiga dari seluruh permukaan bumi.",
    ),

    // --- MATEMATIKA & LOGIKA ---
    QuizQuestion(
      question: "Berapakah hasil dari sepuluh ditambah lima?",
      options: ["Dua belas", "Empat belas", "Tiga belas", "Lima belas"],
      correctIndex: 3,
      explanation: "Sepuluh ditambah lima adalah lima belas.",
    ),
    QuizQuestion(
      question: "Satu jam terdiri dari berapa menit?",
      options: ["Tiga puluh", "Enam puluh", "Sembilan puluh", "Empat puluh lima"],
      correctIndex: 1,
      explanation: "Satu jam tepat memiliki enam puluh menit.",
    ),
    QuizQuestion(
      question: "Berapakah hasil dari lima dikali lima?",
      options: ["Dua puluh", "Tiga puluh", "Dua puluh lima", "Sepuluh"],
      correctIndex: 2,
      explanation: "Lima kali lima adalah dua puluh lima.",
    ),

    // --- UMUM & HIBURAN ---
    QuizQuestion(
      question: "Siapakah pencipta lagu kebangsaan Indonesia Raya?",
      options: ["Ibu Sud", "Ismail Marzuki", "W.R. Supratman", "Kusbini"],
      correctIndex: 2,
      explanation: "Wage Rudolf Supratman adalah pencipta lagu Indonesia Raya.",
    ),
    QuizQuestion(
      question: "Vitamin apa yang banyak terkandung dalam buah jeruk?",
      options: ["Vitamin A", "Vitamin B", "Vitamin C", "Vitamin D"],
      correctIndex: 2,
      explanation: "Jeruk terkenal sebagai sumber utama Vitamin C.",
    ),
    QuizQuestion(
      question: "Alat musik yang dipetik adalah?",
      options: ["Seruling", "Gitar", "Gendang", "Biola"],
      correctIndex: 1,
      explanation: "Gitar adalah alat musik dawai yang dimainkan dengan cara dipetik.",
    ),
    QuizQuestion(
      question: "Benua manakah yang dikenal dengan julukan Benua Biru?",
      options: ["Eropa", "Amerika", "Asia", "Afrika"],
      correctIndex: 0,
      explanation: "Eropa dijuluki benua biru karena mayoritas penduduknya bermata biru.",
    ),
    QuizQuestion(
      question: "Mamalia laut yang terkenal sangat cerdas adalah?",
      options: ["Hiu", "Paus", "Lumba-lumba", "Penyu"],
      correctIndex: 2,
      explanation: "Lumba-lumba adalah mamalia laut yang memiliki kecerdasan tinggi.",
    ),
    QuizQuestion(
      question: "Negara manakah yang memenangkan Piala Dunia sepak bola 2022?",
      options: ["Prancis", "Brasil", "Jerman", "Argentina"],
      correctIndex: 3,
      explanation: "Argentina menjadi juara Piala Dunia 2022 di Qatar.",
    ),
    QuizQuestion(
      question: "Mata uang negara Amerika Serikat adalah?",
      options: ["Euro", "Yen", "Dollar", "Rupiah"],
      correctIndex: 2,
      explanation: "Dollar AS adalah mata uang yang digunakan di Amerika Serikat.",
    ),
    QuizQuestion(
      question: "Berapakah jumlah sila dalam Pancasila?",
      options: ["Tiga", "Empat", "Lima", "Enam"],
      correctIndex: 2,
      explanation: "Pancasila terdiri dari lima dasar negara Indonesia.",
    ),
    QuizQuestion(
      question: "Olahraga yang menggunakan raket dan kok disebut?",
      options: ["Tenis", "Basket", "Voli", "Bulutangkis"],
      correctIndex: 3,
      explanation: "Bulutangkis atau Badminton menggunakan raket dan kok.",
    ),
    QuizQuestion(
      question: "Ibukota dari negara Malaysia adalah?",
      options: ["Singapura", "Kuala Lumpur", "Jakarta", "Manila"],
      correctIndex: 1,
      explanation: "Kuala Lumpur adalah ibukota negara Malaysia.",
    ),
  ];

  QuizQuestion getRandomQuestion() {
    final random = Random();
    return _localQuestions[random.nextInt(_localQuestions.length)];
  }
}
