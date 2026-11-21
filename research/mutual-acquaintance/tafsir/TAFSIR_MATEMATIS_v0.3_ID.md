# Tafsir Matematis — Tractatus de Perceptione et Amore

*Model, contoh, teorema, dan batas pengetahuan di balik tujuh bagian Tractatus.*

**Edisi pendamping v0.3 — 21 November 2026**  
**Naskah yang ditafsirkan:** *Tractatus de Perceptione et Amore*, edisi kanonis Indonesia **v1.1.0** (19 November 2026; 116 proposisi aktif).  
**Kedudukan:** tafsir dan penjelasan, **bukan** bab tambahan dalam Tractatus, bukan pengganti teks aslinya, dan bukan teori psikologi yang telah diuji.

## Sebelum membaca: apa yang hendak dijelaskan?

Ketika A dan B mulai saling mengenal, setidaknya ada enam hal yang jangan dicampuradukkan: **A**, **B**, gambaran A tentang B (**P_A(B)**), gambaran B tentang A (**P_B(A)**), gambaran pasangan yang diinginkan A (**I_A**), dan gambaran pasangan yang diinginkan B (**I_B**). Keenamnya tidak selalu tetap. Dari sini muncul persoalan utama: bagaimana dua orang bisa saling mengenal cukup baik untuk membuat **pilihan bersama yang sadar**, sementara pemahaman, keinginan, dan hubungan mereka sendiri mungkin berubah?

Tafsir ini mengikuti urutan tujuh bagian Tractatus. Setiap bagian bermula dari proposisi asli, kemudian memberi **penjelasan**, **model** bila membantu, serta **teorema, bukti singkat, atau contoh tandingan** bila memang diperlukan. Sebuah *teorema* hanya menyatakan apa yang mengikuti dari asumsi matematisnya. Sebuah *contoh tandingan* cukup menunjukkan bahwa suatu kesimpulan tidak berlaku selalu; ia bukan laporan tentang perilaku manusia. Persamaan pada §5.31 adalah syarat dari definisi hubungan sukarela, **bukan** penemuan empiris.

### Peta kecil model

Pada waktu \(t\), kita dapat membayangkan keadaan dua orang sebagai

\[
S_t=(x_{A,t},x_{B,t},q_{A,t},q_{B,t},r_t,c_t).
\]

- \(x_{A,t},x_{B,t}\): sifat, keadaan, dan kecenderungan yang **sedang dimodelkan**, bukan seluruh pribadi.
- \(q_{A,t},q_{B,t}\): preferensi yang berlaku pada masing-masing orang. Gambaran ideal \(I_A,I_B\) bisa menjadi **representasi yang mereka sadari** tentang preferensi itu; keduanya tidak harus sama persis.
- \(r_t\): keadaan relasional yang bergantung pada pengalaman bersama, misalnya pola koordinasi atau kedekatan yang dialami. Nilainya tidak harus sama dirasakan oleh A dan B; model yang lebih kaya dapat memuat beberapa komponen.
- \(c_t\): konteks perjumpaan.

A dan B tidak melihat \(S_t\) seluruhnya. Mereka memiliki pengalaman dan informasi masing-masing, \(h_{A,t}\) dan \(h_{B,t}\), yang menghasilkan gambaran berbeda. Bila digunakan model probabilistik, keyakinan A dan B dapat ditulis \(\pi_{A,t}(S)\) dan \(\pi_{B,t}(S)\). Notasi ini **alat bantu**, bukan klaim bahwa manusia menghitung probabilitas di kepalanya.

Satu pertemuan dapat menyebabkan tiga macam perubahan yang **berbeda**:

\[
\underbrace{\pi_{i,t}\longrightarrow\pi_{i,t+1}}_{\text{yang dipelajari}}
\qquad
\underbrace{q_{i,t}\longrightarrow q_{i,t+1}}_{\text{yang diinginkan}}
\qquad
\underbrace{r_t\longrightarrow r_{t+1}}_{\text{yang terbentuk di antara keduanya}}.
\]

Ketiganya bisa terjadi bersamaan, tetapi satu perubahan tidak otomatis membuktikan dua yang lain. Inilah inti matematis tafsir.

---

## 1. Orang yang nyata dan orang dalam pikiran kita

> **§1.** Seseorang yang kita kenal tidak selalu sama dengan seseorang yang kita pikir kita kenal.

**Tafsir.** Perbedaan antara A dan \(P_B(A)\) adalah perbedaan antara **orang yang menjadi sasaran penilaian** dan **penilaian tentang orang itu**. Boleh jadi B memiliki alasan kuat untuk mempercayai suatu gambaran; tetap saja gambaran itu dapat benar pada satu konteks dan salah pada konteks lain. Ketulusan perasaan tidak menjamin ketepatan gambaran (§§1.31, 1.52).

**Contoh.** A dan B menghadiri pertemuan yang sama. A tahu bahwa ucapan seseorang merupakan kelanjutan lelucon lama; B tidak mengetahui latar itu. A dan B melihat kata-kata yang sama, tetapi mendapatkan informasi yang berbeda. Ini tidak membuktikan bahwa A selalu lebih tepat: hanya memperlihatkan mengapa pengalaman yang tampak sama tidak harus menghasilkan pengetahuan yang sama (§§1.4, 1.42, 6.51).

**Contoh formal (C1).** Anggap fakta tersembunyi \(\Theta\) dan petunjuk privat \(K\) masing-masing berupa bit adil dan saling bebas. Keduanya melihat \(Y=\Theta\oplus K\), tetapi hanya A mengetahui \(K\). A dapat menghitung \(\Theta=Y\oplus K\); B tidak dapat membedakan kedua kemungkinan \(\Theta\) hanya dari \(Y\). **Bukti:** operasi XOR dua kali dengan bit yang sama mengembalikan bit semula, sedangkan untuk B setiap nilai \(Y\) sama mungkin pada kedua nilai \(\Theta\). Ini konstruksi ilustratif yang diperiksa dalam Lean untuk identitas bitnya, **bukan** model psikologis yang terukur.

**Batas tafsir.** Lebih yakin tidak selalu berarti lebih akurat. Untuk menilai akurasi, kita harus menentukan *apa* yang dinilai dan membandingkannya dengan keadaan sebenarnya, bukan hanya mengukur kepastian subjektif.

## 2. Apa yang diketahui, dan kapan kita sudah tahu cukup?

> **§2.21.** Satu kejadian dapat sesuai dengan beberapa penjelasan; tanpa informasi tambahan, kita belum beralasan memilih salah satunya sebagai yang benar.
>
> **§2.7.** Cukup mengenal seseorang juga bergantung pada pilihan apa yang sedang dipertimbangkan.

**Tafsir.** Seseorang yang tidak membalas pesan bisa sedang sibuk, lupa, lelah, atau tidak ingin berbicara. Kejadian diam itu *sesuai* dengan beberapa cerita, tetapi belum *memilihkan* salah satunya bagi kita. Mengulangi kejadian yang sama tidak selalu menjawab pertanyaan yang berbeda: bagaimana seseorang bertindak di keadaan lain (§2.61).

**Teorema 2.1 — Pengulangan belum tentu membedakan (T2).** Misalkan dua hipotesis \(\theta_0\) dan \(\theta_1\) mempunyai peluang awal positif. Jika **seluruh riwayat observasi** \(H_n\) mempunyai distribusi yang sama di bawah dua hipotesis tersebut, pada setiap panjang riwayat \(n\), maka perbandingan peluang posteriornya sama dengan perbandingan peluang awal:

\[
\frac{\Pr(\theta_0\mid H_n=h)}{\Pr(\theta_1\mid H_n=h)}
=
\frac{\Pr(\theta_0)}{\Pr(\theta_1)}
\]

untuk riwayat dengan likelihood positif. **Bukti.** Aturan Bayes mengalikan perbandingan peluang awal dengan rasio likelihood. Karena kedua likelihood sama, faktor itu bernilai satu. **Penting:** yang diasumsikan sama adalah distribusi **riwayat lengkap**, bukan sekadar distribusi sebuah pertemuan. Perjumpaan berulang sungguh dapat membantu bila menghadirkan informasi yang membedakan.

**Teorema 2.2 — Mengetahui segalanya tidak selalu diperlukan (T3, versi dua keadaan/dua pilihan).** Anggap ada dua keadaan mungkin, dua pilihan tersedia, utilitas tetap, dan informasi dapat diperoleh tanpa biaya. Nilai informasi sempurna **nol jika dan hanya jika** ada satu pilihan yang paling baik pada setiap keadaan yang masih mungkin, termasuk jika ada nilai seri.

**Bukti singkat.** Informasi sempurna memungkinkan kita memilih tindakan terbaik secara terpisah pada tiap keadaan; tanpa informasi kita memilih satu tindakan untuk keduanya. Nilai pertama tidak lebih kecil dari yang kedua. Keduanya sama persis bila satu tindakan sudah mencapai maksimum untuk setiap keadaan yang mempunyai peluang positif. Jika tidak ada tindakan bersama seperti itu, setiap tindakan tetap kehilangan nilai pada sedikitnya satu keadaan dengan peluang positif, sehingga informasi sempurna memberi peningkatan.

**Contoh.** Dalam dua keadaan yang belum dapat dibedakan, pilihan X memberikan nilai 2 dan 2, sedangkan Y memberi 1 dan 1. Kita belum tahu keadaan mana yang benar, tetapi hal itu tidak mengubah keputusan memilih X. Artinya, **cukup tahu untuk satu keputusan** tidak berarti **tahu segalanya tentang seseorang** (§§2.71–2.72). Pada keputusan nyata, biaya kesalahan, pilihan yang tersedia, dan hak pihak lain juga harus dipertimbangkan; teorema tidak menentukan ambang universal untuk sebuah hubungan.

## 3. Orang yang kita harapkan, dan keinginan yang berubah

> **§3.23.** Yang pertama membuat kita mengenali keinginan lama. Yang kedua membuat keinginan itu berubah. Kedengarannya mirip, dan kadang memang sulit dibedakan, bahkan oleh diri sendiri.

**Tafsir.** \(I_A\) dan \(I_B\) bukan sosok yang nyata. Keduanya adalah gambaran tentang kualitas yang dianggap penting. Ketika A bertemu B, A membandingkan \(P_A(B)\) dengan \(I_A\), bukan serta-merta membandingkan B yang utuh dengan keinginan yang sudah tetap. Ketertarikan, kecocokan dalam pengalaman bersama, dan kesediaan memilih adalah tiga pertanyaan berlainan (§§3.3–3.6).

**Contoh tandingan 3.1 — Jawaban berubah, tetapi penyebabnya belum diketahui (C2).** Bayangkan jawaban yang terdengar \(Y_t=Q_t\oplus C_t\): \(Q_t\) adalah preferensi yang sebenarnya dimodelkan, dan \(C_t\) adalah pengaruh konteks pelaporan.

- **Penjelasan pertama:** \(Q=(0,0)\), \(C=(0,1)\), sehingga jawaban \(Y=(0,1)\). Preferensinya tetap, konteks penyampaiannya berubah.
- **Penjelasan kedua:** \(Q=(0,1)\), \(C=(0,0)\), sehingga jawaban yang tampak **juga** \(Y=(0,1)\). Preferensinya berubah, konteks tetap.

**Bukti:** kedua pasangan menghasilkan urutan observasi yang identik menurut rumus yang sama. Dari jawaban saja, dua mekanisme itu tidak dapat dibedakan. Bila konteks diketahui dan aturan pelaporan benar, ambiguitas khusus ini dapat hilang. Contoh tersebut tidak membuktikan seseorang menyembunyikan perasaan atau berubah pikiran; ia menunjukkan mengapa **perubahan laporan** belum cukup untuk menyimpulkan **perubahan preferensi**.

**Pertanyaan yang tetap terbuka.** Kapan seseorang menemukan kesukaan yang sebelumnya tidak ia sadari, kapan ia benar-benar memperoleh kesukaan baru, dan data apa yang mampu membedakannya? Model memberi nama pada persoalan itu, bukan jawaban tentang individu tertentu.

## 4. Maksud, kata-kata, dan rasa dimengerti

> **§4.53.** Ada percakapan yang membuat kita merasa dimengerti. Apakah maksud kita benar-benar tertangkap, itu pertanyaan lain.
>
> **§4.54.** Respons terhadap cerita orang lain dapat memengaruhi kedekatan yang dirasakan, bahkan ketika ketepatan saling memahami masih belum pasti.

**Tafsir.** Sekurang-kurangnya ada empat hal yang berbeda: **maksud** seseorang, **kata-kata atau tindakan** yang disampaikan, **penafsiran** penerima, dan **perasaan dipahami**. Orang bisa tulus, tetapi disalahpahami. Orang bisa merasa didengarkan, sementara sebagian maksudnya belum ditangkap. Yang satu tidak meniadakan yang lain.

**Contoh tandingan 4.1 — Diam tidak menentukan niat (C3).** Dalam model kecil, dua niat \(m_0\) dan \(m_1\) sama-sama menghasilkan tanda terlihat “diam”. Karena observasinya sama, observasi tunggal itu tidak cukup menentukan niat yang mana. **Bukti:** fungsi pengamatan memberikan hasil yang sama untuk dua masukan berlainan; tidak ada pembalik tunggal dari hasil itu ke niat. Tambahan konteks bisa mengubah kesimpulan.

**Yang tidak dibuktikan.** Teori itu tidak menyatakan bahwa respons empatik *pasti* membuat orang dekat, atau bahwa rasa dipahami *pasti* keliru. Hubungan empiris antara respons dan kedekatan harus diuji secara terpisah. Tafsir ini hanya meminta agar **pengalaman dimengerti** tidak disamakan dengan **ketepatan membaca pikiran**.

## 5. Dua orang, dua pilihan yang tidak dapat digantikan

> **§5.** Hubungan antara dua orang tidak dapat ditentukan oleh keinginan salah satu pihak saja.

**Tafsir.** A tidak memilih bagi B, dan B tidak memilih bagi A. Bahkan bila masing-masing sudah mengetahui preferensinya dengan baik, pilihan mereka bisa berbeda. Kesediaan seseorang tidak menjadi kewajiban pihak yang lain.

**Definisi, bukan teorema penemuan (§§5.3–5.32).** Misalkan \(W_A(B,t)\) dan \(W_B(A,t)\) menyatakan kesediaan masing-masing pada waktu \(t\). Jika \(H(A,B,t)\) berarti hubungan **yang sungguh dijalani secara sukarela oleh keduanya**, maka

\[
H(A,B,t)\ \Longrightarrow\
W_A(B,t)\land W_B(A,t).
\]

**Mengapa benar?** Karena “dijalani secara sukarela oleh keduanya” sudah mencakup kesediaan kedua pihak. Ini penjelasan arti konsep, bukan prediksi bahwa keduanya akan bersedia; dua kesediaan pun belum menjamin keadaan memungkinkan hubungan itu (§5.33).

**Teorema 5.1 — Batas peluang kesediaan bersama (T4).** Jika \(p_A=\Pr(W_A=1)\) dan \(p_B=\Pr(W_B=1)\), tanpa mengasumsikan keduanya bebas, maka

\[
\max(0,p_A+p_B-1)\ \le\
\Pr(W_A=1,W_B=1)\
\le\ \min(p_A,p_B).
\]

**Bukti.** Peristiwa “keduanya bersedia” adalah bagian dari masing-masing peristiwa kesediaan, sehingga peluangnya tidak dapat melebihi salah satunya. Di sisi lain, peluang gabungan dua peristiwa paling besar satu; rumus penjumlahan peluang memberi \(p_A+p_B-\Pr(W_A\land W_B)\le1\). Peluang juga tidak mungkin negatif. Kedua batas dapat dicapai oleh susunan ketergantungan yang berbeda.

**Contoh.** Jika peluang kesediaan A dan B masing-masing 0,6, peluang bersama bisa berada antara **0,2 dan 0,6**. Angka 0,36 baru diperoleh bila ada asumsi **independensi**. Dalam hidup nyata, pilihan dua orang justru bisa saling memengaruhi. Teorema ini bukan alat meramalkan pasangan tertentu; ia hanya menunjukkan mengapa dua peluang pribadi tidak otomatis menentukan peluang kebersamaan.

## 6. Ketika pertemuan mengungkap sesuatu, dan menciptakan sesuatu

> **§6.63.** Mengetahui orang lain, menyadari apa yang kita inginkan, dan mengalami perubahan dalam hubungan adalah tiga hal berbeda. Meski begitu, ketiganya bisa terjadi dalam satu pertemuan yang sama.
>
> **§6.92.** Ada hal yang sebenarnya sudah ada, hanya belum kita ketahui. Ada juga yang memang baru terbentuk ketika dua orang menjalani sesuatu bersama.

**Tafsir inti.** Sebelum sebuah pertemuan, mungkin sudah ada kebiasaan A yang belum diketahui B. Percakapan dapat *mengungkap* kebiasaan itu. Tetapi ada pula sesuatu yang belum ada sebelumnya—misalnya pola berbicara yang baru terbentuk lewat saling menanggapi. Percakapan dapat turut *membentuk* keadaan tersebut. Ini bukan dua nama bagi proses yang sama.

**Teorema 6.1 — Informasi pasif yang gratis tidak menurunkan nilai keputusan (T5).** Ambil keadaan tetap, pilihan yang sama sebelum/sesudah informasi, fungsi manfaat tetap, dan sinyal tambahan tanpa biaya yang boleh diabaikan. Nilai keputusan optimal setelah melihat sinyal paling tidak sebesar nilai tanpa sinyal.

**Bukti singkat.** Setelah menerima sinyal, pengambil keputusan selalu boleh menjalankan keputusan lama. Maka pilihan optimal setelah sinyal tidak mungkin lebih buruk dari keputusan lama dalam perhitungan nilai harapan. Kesamaan berlaku bila ada satu tindakan yang optimal bagi semua sinyal yang mungkin muncul dengan peluang positif. **Batas:** ini teorema tentang **mengamati** keadaan yang tetap, bukan teorema bahwa setiap pertanyaan atau pertemuan bermanfaat.

**Contoh tandingan 6.1 — Bertanya juga merupakan tindakan (C4; §6.8).** Seorang pengamat dapat memilih diam dan menebak sebuah fakta tersembunyi, atau mengajukan “uji” yang mengungkap fakta itu secara sempurna tetapi, **menurut asumsi contoh**, mengurangi nilai keadaan relasional. Tetapkan peluang tebakan benar tanpa uji sebesar 1/2. Beri nilai relasional 2 bila tidak menguji dan 0 bila menguji. Nilai total tanpa uji adalah \(1/2+2=2{,}5\), sedangkan dengan uji adalah \(1+0=1\). Pengamatan menjadi lebih tepat, tetapi nilai total dalam model justru lebih kecil. **Bukti:** hitung dua nilai tersebut. Angka dan dampak relasional sengaja **ditetapkan sebagai asumsi**, bukan temuan bahwa mengajukan pertanyaan merusak kedekatan.

**Contoh tandingan 6.2 — Daftar sifat tidak selalu menentukan hubungan (C5).** Misalkan dua riwayat pertemuan berakhir dengan sifat individual A dan B yang sama, tetapi \(r=0\) pada riwayat pertama dan \(r=1\) pada riwayat kedua. Tidak mungkin ada satu fungsi **tepat dan deterministik** \(r=f(x_A,x_B)\) yang benar pada keduanya. **Bukti:** masukan sama harus menghasilkan keluaran sama, tetapi contoh mensyaratkan keluaran berbeda. Ini tidak mengatakan sifat individu tidak berguna untuk *prediksi probabilistik*.

**Teorema 6.2 — Kapan ringkasan cukup untuk memprediksi?** Untuk kumpulan riwayat yang diizinkan, tulis \(S(h)\) sebagai ringkasan yang diketahui (misalnya dua profil) dan \(R(h)\) sebagai hasil relasional biner. Ada fungsi \(f\) sehingga \(R(h)=f(S(h))\) untuk setiap riwayat **jika dan hanya jika** semua riwayat dengan ringkasan sama memiliki hasil \(R\) yang sama.

**Bukti.** Jika \(f\) ada, masukan ringkasan sama pasti menghasilkan hasil sama. Sebaliknya, bila setiap kelompok ringkasan memiliki satu hasil, definisikan \(f\) dengan hasil kelompok itu; nilai pada ringkasan yang tak pernah terjadi boleh dipilih sembarang. Teorema ini memperjelas apa yang diperlukan agar informasi tentang dua orang *cukup* untuk hasil yang ingin diperkirakan.

**Contoh tandingan 6.3 — Masa depan alternatif tidak dapat dibaca dari satu pilihan aktual (C6; §§6.41–6.43).** Dua model, M dan N, sama-sama menghasilkan hasil 0 ketika tindakan \(a_0\) dipilih. Pada tindakan \(a_1\) yang tidak pernah dicoba, M memprediksi 1, N memprediksi 0. Karena data aktual pada \(a_0\) sama, data itu saja tidak membedakan kedua model. Maka hasil \(a_1\) belum teridentifikasi dari riwayat tersebut. Ini **bukan** bukti bahwa semua kemungkinan alternatif mustahil dipelajari: penelitian dan asumsi tambahan kadang dapat mengidentifikasi atau membatasinya.

**§6.93 — Perubahan yang tampak belum mengungkap mekanismenya.** Misalkan \(m\) adalah proporsi keadaan tersembunyi yang benar-benar berpindah dari 0 ke 1 setelah pertemuan, sedangkan \(q=c_1-c_0\) adalah selisih peluang melaporkan “positif” antara keadaan tersembunyi 1 dan 0. Dalam model biner **dengan kanal laporan yang sama sebelum/sesudah**, proporsi awal yang sebanding, serta perpindahan hanya 0-ke-1, perubahan laporan positif memenuhi

\[
\Delta=mq.
\]

**Bukti:** jika proporsi awal keadaan 1 adalah \(p\), laporan positif semula \(y_0=c_0+pq\); sesudahnya \(y_1=c_0+(p+m)q\). Mengurangkan memberi \(\Delta=y_1-y_0=mq\). Dari \(\Delta\) saja, \(m\) belum tentu diketahui karena \(q\) juga bisa tidak diketahui.

**Hasil bersyarat yang lebih tajam (I1).** Bila \(0<p<1\) diketahui, kanal pelaporan sama dan berorientasi positif namun belum dikalibrasi, \(\Delta>0\), dan data kompatibel dengan model, definisikan

\[
q_{\max}=\min\left(\frac{y_0}{p},\frac{1-y_0}{1-p}\right).
\qquad
\frac{\Delta}{q_{\max}}\le m\le1-p.
\]

**Bukti ringkas:** batas \(c_0\ge0\) dan \(c_1\le1\) memberi \(q\le q_{\max}\); batas \(m\le1-p\) berasal dari jumlah keadaan 0 yang tersedia. Untuk setiap \(m\) dalam interval, ambil \(q=\Delta/m\), \(c_0=y_0-pq\), \(c_1=c_0+q\); pilihan itu mereproduksi observasi dan mematuhi batas peluang. Jadi batasnya *tajam dalam model ini*. Sebagai contoh, untuk \(p=1/4\), \(y_0=3/8\), dan \(y_1=5/8\), hasilnya \(3/10\le m\le3/4\). Jika kanal laporan berubah, kelompok awal berbeda, atau transisi dapat terjadi ke dua arah, kesimpulan tersebut **tidak dapat dipakai tanpa penyesuaian**.

**Maksud filosofisnya.** Seorang yang tampak lebih dekat setelah pertemuan mungkin memperlihatkan sesuatu yang sudah ada, membentuk hal baru, mengubah cara melaporkan perasaannya, atau kombinasi di antaranya. Observasi sebuah perubahan **belum** menjawab perubahan jenis yang mana. Ketelitian di sini justru menahan kita dari kesimpulan yang terlalu cepat.

## 7. Apa yang dapat dikatakan model, dan apa yang tetap merupakan pengalaman

> **§7.** Kita bisa mengetahui banyak hal tentang seseorang. Tapi selama saling mengenal, ada yang baru terlihat, ada yang baru terbentuk, dan ada yang tetap belum kita ketahui. Tidak semua yang dialami bersama selesai dalam kata-kata.

**Tafsir.** Matematika membantu kita membedakan beberapa jenis ketidaktahuan: belum melihat informasi, memperoleh laporan yang ambigu, belum mengalami keadaan tertentu, atau menghadapi keadaan relasional yang belum terbentuk. Ia juga menjelaskan kondisi logis saat keputusan sudah dapat dibuat tanpa mengetahui segala sesuatu.

Tetapi **persamaan bukan orang yang dipersamakan**. Sebuah model dapat menjelaskan mengapa dua riwayat yang sama di permukaan tidak selalu mempunyai arti sama. Model tidak dapat, hanya dengan teorema di sini, menentukan apa yang sedang dirasakan A atau B, siapa yang harus memilih siapa, ataupun menyimpulkan bahwa pengalaman manusia secara prinsip tidak bisa dikatakan dengan kata-kata. Bagian penutup ini adalah **batas tafsir**, bukan teorema tentang sesuatu yang tak terkatakan.

---

## Catatan pembaca: apa yang sudah dibuktikan?

| Bagian Tractatus | Bentuk hasil dalam tafsir | Makna terbatas |
| --- | --- | --- |
| §§1.4, 6.51 | C1, contoh sinyal dengan informasi privat | Peristiwa terlihat sama dapat menghasilkan pengetahuan berbeda |
| §2.61 | T2, teorema likelihood riwayat sama | Pengulangan tidak selalu membedakan hipotesis |
| §§2.7–2.72 | T3, teorema keputusan | Informasi lengkap tidak selalu diperlukan untuk memilih |
| §3.23 | C2, dua mekanisme menghasilkan laporan sama | Laporan berubah tidak menentukan penyebabnya |
| §§4.61–4.62 | C3, observasi diam | Satu tanda tidak harus menentukan niat |
| §§5.3–5.32 | D1, syarat dalam definisi | Langkah sukarela bersama memerlukan kedua kesediaan |
| §5.3 | T4, batas peluang gabungan | Peluang individual tidak menetapkan peluang bersama |
| §§6.63, 6.8 | T5 dan C4 | Manfaat informasi pasif tidak otomatis berlaku pada intervensi |
| §§6.64, 6.92 | C5 dan kriteria prediktor | Hasil relasional dapat bergantung pada riwayat |
| §§6.41–6.43 | C6, dua dunia alternatif | Satu tindakan aktual tidak menentukan hasil tindakan yang tak diambil |
| §6.93 | I1, batas identifikasi biner | Perubahan laporan tidak langsung mengukur pembentukan keadaan laten |
| §7 | Tafsir, tanpa teorema | Model tidak boleh disamakan dengan seluruh pengalaman |

**Tentang status bukti.** Lean 4 yang menyertai proyek memeriksa **hasil-hasil finit tertentu**, termasuk identitas bit, kesediaan bersama, batas-batas aljabar, contoh sejarah yang berbeda, dan konstruksi identifikasi dengan asumsi tertentu. Formulasi probabilistik umum, seluruh teorema yang ditulis dalam bahasa biasa, dan asumsi psikologis **tidak seluruhnya diformalisasi dalam Lean**. Kompilasi Lean membuktikan ketepatan langkah formal yang diperiksa terhadap asumsi di kode; ia **tidak** membuktikan bahwa suatu pasangan nyata memiliki keadaan atau peluang yang diasumsikan.

**Rujukan pendalaman, bila ingin memeriksa setiap langkah:** [naskah matematis rinci v0.2](../paper/A_Dynamic_Epistemic_Model_of_Mutual_Acquaintance_WORKING_DRAFT.md); [indeks lengkap 116 proposisi](../paper/PROPOSITION_INDEX.md); [catatan dinamika](../notes/DYNAMICS_ADDENDUM.md); [catatan identifikasi](../notes/IDENTIFICATION_SENSITIVITY.md); [audit kesesuaian naskah dan bukti](../COMPANION_ALIGNMENT_v1.1.0.md); dan [kode Lean](../lean/). Semua sumber tersebut tetap tersedia bagi pembaca yang memerlukan syarat, perhitungan, atau cakupan verifikasi lebih lengkap.

## Penutup

Pertanyaan yang penting dalam Tractatus bukan sekadar “seberapa banyak aku mengetahui kamu?”, melainkan juga: **apa yang sebenarnya kuketahui, apa yang masih kuduga, apa yang berubah selama kita bertemu, dan pilihan apa yang sungguh dapat kita buat bersama?**

Jawaban formal yang paling berguna justru terbatas: **pengetahuan tidak sama dengan keyakinan; pilihan tidak sama dengan ketertarikan; dan sesuatu yang diketahui karena perjumpaan tidak selalu sama dengan sesuatu yang baru ada karena perjumpaan itu.** Di atas pembedaan itulah pemahaman yang lebih hati-hati dapat dibangun.
