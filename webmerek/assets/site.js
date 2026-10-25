/* Progressive enhancement only. No analytics, storage, fetch, or automatic sharing. */
(() => {
  'use strict';
  const config = window.WEBMEREK || {mode: 'preview', contactVerified: false};
  const one = (selector) => document.querySelector(selector);
  const menu = one('.menu-toggle');
  const nav = one('#main-nav');
  if (menu && nav) {
    const closeMenu = () => { nav.classList.remove('is-open'); menu.setAttribute('aria-expanded', 'false'); };
    menu.addEventListener('click', () => {
      const open = menu.getAttribute('aria-expanded') !== 'true';
      menu.setAttribute('aria-expanded', String(open));
      nav.classList.toggle('is-open', open);
    });
    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && menu.getAttribute('aria-expanded') === 'true') {
        closeMenu(); menu.focus();
      }
    });
    nav.addEventListener('click', (event) => { if (event.target.closest('a')) closeMenu(); });
    menu.hidden = false;
    document.documentElement.classList.add('nav-enhanced');
  }

  const form = one('#brief-form');
  if (form) {
    const output = one('#brief-output');
    const text = one('#brief-text');
    const status = one('#brief-status');
    const consent = one('#share-consent');
    const share = one('#share-whatsapp');
    const phone = String(config.whatsapp || '');
    const canShare = config.mode === 'live' && config.contactVerified === true && /^[1-9][0-9]{7,14}$/.test(phone);
    let brief = '';
    const value = (name) => String(form.elements.namedItem(name).value || '').trim();
    const selectedLabel = (name) => {
      const select = form.elements.namedItem(name);
      return select.selectedOptions[0]?.textContent || '';
    };
    const invalidate = () => {
      brief = ''; output.hidden = true; consent.checked = false; share.disabled = true;
    };
    form.addEventListener('input', invalidate);
    form.addEventListener('change', invalidate);
    form.addEventListener('submit', (event) => {
      event.preventDefault();
      if (!form.reportValidity()) return;
      if (!value('bisnis') || !value('tujuan')) {
        status.textContent = 'Nama bisnis dan tujuan tidak boleh hanya berisi spasi.';
        output.hidden = false; output.focus(); return;
      }
      brief = [
        'BRIEF WEBMEREK — BELUM DIKIRIM',
        '',
        'Nama: ' + (value('nama') || 'Tidak diisi'),
        'Bisnis: ' + value('bisnis'),
        'Kebutuhan: ' + selectedLabel('paket'),
        'Kisaran anggaran: ' + selectedLabel('anggaran'),
        'Harapan waktu: ' + (value('waktu') || 'Belum ditentukan'),
        '',
        'Tujuan / kebutuhan:',
        value('tujuan'),
        '',
        'Ringkasan ini bukan pemesanan atau kontrak. Harga dan lingkup perlu penawaran tertulis.'
      ].join('\n');
      text.textContent = brief;
      status.textContent = 'Brief disusun di perangkat Anda. Belum dikirim ke WebMerek.';
      consent.checked = false;
      share.disabled = true;
      one('#send-options').hidden = !canShare;
      output.hidden = false;
      output.focus();
    });
    one('#download-brief').addEventListener('click', () => {
      if (!brief) return;
      const url = URL.createObjectURL(new Blob([brief + '\n'], {type: 'text/plain;charset=utf-8'}));
      const link = document.createElement('a');
      link.href = url; link.download = 'brief-webmerek.txt';
      document.body.append(link); link.click(); link.remove();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
      status.textContent = 'Unduhan brief dimulai. Tidak ada pesan yang dikirim.';
    });
    one('#copy-brief').addEventListener('click', async () => {
      if (!brief) return;
      try {
        if (!navigator.clipboard?.writeText) throw new Error('Clipboard unavailable');
        await navigator.clipboard.writeText(brief);
        status.textContent = 'Brief disalin. Anda menentukan sendiri ke mana akan membagikannya.';
      } catch {
        const range = document.createRange(); range.selectNodeContents(text);
        const selection = window.getSelection(); selection.removeAllRanges(); selection.addRange(range);
        status.textContent = 'Akses clipboard tidak tersedia. Teks dipilih; gunakan Salin pada perangkat atau tombol unduh.';
      }
    });
    consent.addEventListener('change', () => { share.disabled = !(consent.checked && canShare && brief); });
    share.addEventListener('click', () => {
      if (!canShare || !consent.checked || !brief) return;
      const link = document.createElement('a');
      link.href = 'https://wa.me/' + phone + '?text=' + encodeURIComponent(brief);
      link.target = '_blank'; link.rel = 'noopener noreferrer';
      document.body.append(link); link.click(); link.remove();
      status.textContent = 'WhatsApp diminta terbuka. Pesan belum dikonfirmasi terkirim; Anda perlu menekan Kirim di WhatsApp.';
    });
    const choice = new URLSearchParams(window.location.search).get('paket');
    if (['fondasi', 'website', 'lengkap', 'diskusi'].includes(choice)) form.elements.namedItem('paket').value = choice;
    if (canShare) {
      one('#contact-heading').textContent = 'Mulai dengan brief yang jelas.';
      one('#contact-state').textContent = 'WhatsApp resmi: +' + phone + '. Susun dan tinjau brief dahulu; pengiriman selalu pilihan Anda.';
    }
    // Enable only after all listeners are installed: no-JS forms cannot submit personal data.
    form.querySelector('[data-enable]').disabled = false;
  }

  const assessment = one('#assessment-form');
  if (assessment) {
    const result = one('#assessment-result');
    const tips = [
      'Perjelas satu kalimat tentang siapa yang dibantu dan masalah yang diselesaikan.',
      'Satukan logo, warna, dan gaya tulisan dalam panduan singkat.',
      'Kumpulkan bukti kerja yang nyata dan izin untuk menampilkannya.',
      'Jelaskan proses kerja serta satu langkah kontak berikutnya.',
      'Periksa halaman di ponsel dan coba jalur kontak dari awal sampai akhir.'
    ];
    assessment.addEventListener('change', () => { result.hidden = true; });
    assessment.addEventListener('submit', (event) => {
      event.preventDefault();
      if (!assessment.reportValidity()) return;
      const values = [1,2,3,4,5].map(n => Number(one('#a' + n).value));
      if (values.some(v => !Number.isInteger(v) || v < 0 || v > 2)) return;
      const score = values.reduce((sum, value) => sum + value, 0);
      one('#assessment-score').textContent = 'Ringkasan jawaban: ' + score + ' dari 10 poin. Ini hasil refleksi Anda, bukan skor kualitas atau prediksi penjualan.';
      const list = one('#assessment-tips'); list.replaceChildren();
      const priority = values.map((value, index) => ({value, index})).filter(item => item.value < 2).sort((a, b) => a.value - b.value);
      (priority.length ? priority.map(item => tips[item.index]) : ['Semua jawaban sudah jelas menurut Anda. Uji kembali dengan calon pelanggan sebelum menambah investasi.']).forEach(tip => {
        const li = document.createElement('li'); li.textContent = tip; list.append(li);
      });
      result.hidden = false; result.focus();
    });
    assessment.querySelector('[data-enable]').disabled = false;
  }
})();
