# Pengaturan Godot 4 untuk IndoFight

Atur lewat Project > Project Settings (aktifkan Advanced Settings), atau tempel bagian di bawah ke `project.godot` saat Godot sedang tertutup. Nama kunci bisa sedikit berbeda antar versi Godot. Bila ragu, atur lewat menu.

```ini
[display]
window/size/viewport_width=480
window/size/viewport_height=270
window/size/window_width_override=1920
window/size/window_height_override=1080
window/stretch/mode="viewport"
window/stretch/aspect="expand"
window/stretch/scale_mode="integer"

[rendering]
textures/canvas_textures/default_texture_filter=0
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true

[physics]
common/physics_ticks_per_second=60
```

Artinya:
- Game digambar di 480 x 270 lalu diperbesar dengan kelipatan bulat. Layar yang lebih lebar, seperti HP 20:9, menampilkan stage lebih banyak ke samping (`aspect="expand"`), tidak meregangkan gambar.
- Filter tekstur Nearest supaya piksel tetap tajam.
- Posisi sprite dibulatkan ke piksel supaya tidak bergetar.
- Logika berjalan 60 tick per detik, sesuai frame data.

Input map yang disarankan (Project > Input Map), mengikuti GDD 4:

| Aksi | Tombol P1 |
| --- | --- |
| p1_left / p1_right / p1_up / p1_down | A / D / W / S |
| p1_lp / p1_hp | J / K |
| p1_lk / p1_hk | U / I |
| p1_block | L |
| p1_skill / p1_ultimate | O / P |

Impor sprite sheet dari SpriteCook ke `SpriteFrames` dan `AnimatedSprite2D` mengikuti skill `spritecook-use-assets-in-godot`. Untuk logika serangan, pakai skill `godot-genre-fighting`. Hitbox jangan bergantung pada sinyal Area2D biasa: pakai query langsung per tick seperti yang dianjurkan skill itu.
