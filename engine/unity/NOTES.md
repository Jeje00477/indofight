# Catatan jika memakai Unity

Langkah yang perlu disiapkan bila proyek pindah ke Unity:

- Proyek baru dengan template 2D URP.
- Pixel Perfect Camera dengan reference resolution 480 x 270.
- Sprite sheet dipotong per 160 x 160, pivot di titik kaki (80, 10 dari bawah).
- Sprite per karakter digabung dalam satu Sprite Atlas.
- Efek ultimate (hitam-putih, merah, bloom ringan) lewat post-processing URP.
- Versus Online: pertimbangkan rollback netcode bila serius.

Pengaturan impor semua sprite: Filter Mode Point, Compression None, Pixels Per Unit sama untuk semua aset (misalnya 32), Mesh Type Full Rect.

Logika tetap 60 tick per detik (Fixed Timestep 1/60) dan frame data disimpan sebagai ScriptableObject.
