# Ringkasan Penelitian

## A Dynamic Epistemic Model of Mutual Acquaintance

*Makalah matematika pendamping Tractatus de Perceptione et Amore*  
18 November 2026

### Pertanyaan utama

Bagaimana dua orang dapat saling mengenal dengan cukup baik untuk membuat pilihan bersama, apabila proses saling mengenal itu sendiri dapat mengubah apa yang mereka ketahui, apa yang mereka inginkan, dan hubungan yang sedang terbentuk di antara mereka?

### Tiga proses yang dibedakan

**1. Perubahan pengetahuan.** Seseorang memperoleh bukti baru tentang diri sendiri atau orang lain, lalu mengubah keyakinannya. Pengalaman bersama tidak berarti informasi yang diperoleh kedua pihak harus sama.

**2. Penemuan atau perubahan preferensi.** Seseorang bisa baru menyadari sesuatu yang sejak awal penting baginya. Bisa juga pengalamannya memang mengubah apa yang dianggap penting. Perubahan laporan tentang preferensi tidak cukup untuk memastikan mana yang terjadi.

**3. Perubahan hubungan.** Interaksi bukan hanya mengungkapkan sifat kedua individu. Ia juga dapat membentuk pengalaman, kebiasaan, dan keadaan hubungan yang sebelumnya belum ada.

Karya filosofis *Tractatus* menyatakan pembedaan ini pada proposisi 6.63, 6.91, dan 6.92. Model matematika menerjemahkannya menjadi sistem dua individu dengan keadaan tersembunyi, pengamatan yang berbeda, preferensi yang dapat berubah, dan keadaan relasional yang bergantung pada riwayat interaksi.

### Delapan hasil formal

| Hasil | Maknanya |
|:--|:--|
| 1. Informasi asimetris | Dua orang dapat menyaksikan peristiwa yang sama tetapi mempelajari hal berbeda. |
| 2. Ketidakidentifikasian dalam satu konteks | Mengulang pengamatan serupa tidak selalu menyelesaikan pertanyaan tentang keadaan lain. |
| 3. Ambiguitas preferensi | Preferensi yang berubah dan perubahan cara melaporkannya bisa menghasilkan pengamatan sama. |
| 4. Nilai informasi pasif | Informasi gratis yang tidak mengubah keadaan tidak merugikan keputusan optimal; nilainya bisa nol. |
| 5. Nilai interaksi aktif | Interaksi dapat memberi informasi tetapi juga mengubah hubungan, sehingga nilai totalnya bisa negatif. |
| 6. Cukup tahu tanpa mengetahui semuanya | Bila informasi yang belum diketahui tidak mengubah keputusan optimal, identifikasi penuh tidak diperlukan. |
| 7. Keadaan hubungan bergantung pada riwayat | Sifat dua orang yang sama tidak dengan sendirinya menentukan pengalaman yang terbentuk di antara mereka. |
| 8. Kontrafaktual | Satu riwayat yang benar-benar dijalani tidak cukup untuk memastikan hasil pilihan yang tidak dijalani. |

Semua pernyataan ini berlaku **dengan asumsi matematis masing-masing**. Tidak satu pun merupakan penilaian tentang manusia nyata atau prediksi perasaan pribadi seseorang.

### Apa yang sudah diverifikasi?

Program Python memeriksa contoh-contoh hingga batas yang dinyatakan dengan perhitungan rasional eksak. Hasilnya **PASS**, termasuk 20.480 kombinasi kecil untuk nilai informasi pasif dan 1.215 kombinasi untuk kriteria kecukupan keputusan. Ini mendukung konsistensi contoh dan pernyataan yang diuji, bukan pembuktian komputasional bagi semua kemungkinan model.

Berkas Lean 4 menyertakan beberapa teorema Boolean dan implikasi logis dasar. **Lean tidak tersedia di lingkungan eksekusi saat penelitian ini dibuat**, sehingga berkas tersebut belum dikompilasi dan tidak boleh disebut kernel-verified.

### Nilai dan keterbatasan

Sumbangan utama makalah ini adalah penyatuan dan pembedaan konsep, bukan klaim pertama kali menemukan teori Bayes, teori permainan, atau dinamika hubungan. Belum ada data empiris yang digunakan untuk mengestimasi parameter model. Langkah riset lanjutan memerlukan desain studi longitudinal, definisi pengukuran yang dapat diuji, serta penilaian apakah model yang lebih rumit benar-benar menjelaskan data lebih baik daripada model sederhana.

Kesimpulan: **sebagian hal sudah ada dan belum diketahui; sebagian hal yang lain justru baru terbentuk melalui pengalaman bersama.** Matematika dapat membedakan kedua keadaan itu dengan jelas. Matematika tidak, tanpa data dan asumsi tambahan, mengetahui isi hati dua orang tertentu.