class_name MatchRules
extends Resource
## Aturan pertarungan. Waktu dalam frame kecuali disebut detik.

@export_group("Ronde")
## Best of 3 berarti menang 2 ronde (docs/decisions.md no. 6).
@export var rounds_to_win: int = 2
@export var round_seconds: int = 99
## Lama teks ROUND dan FIGHT! sebelum bisa bergerak.
@export var intro_frames: int = 96
## Lama jeda setelah K.O. atau TIME UP.
@export var round_end_frames: int = 170
## Jarak awal tiap petarung dari tengah stage (piksel).
@export var start_offset: int = 70

@export_group("Energi")
@export var energy_max: int = 100
## Energi per 100 damage yang diberikan.
@export var energy_per_100_dealt: int = 8
## Energi per 100 damage yang diterima.
@export var energy_per_100_taken: int = 14
@export var energy_on_block_attacker: int = 2
@export var energy_on_block_defender: int = 1

@export_group("Input")
## Tombol yang ditekan sedikit terlalu cepat tetap dihitung selama sekian frame.
@export var input_buffer_frames: int = 8
## Jeda maksimum antara dua ketukan arah untuk dash.
@export var dash_tap_window: int = 12

@export_group("Kombo")
## Damage turun sekian persen untuk tiap pukulan lanjutan dalam satu kombo.
@export var combo_scaling_step: int = 10
@export var combo_scaling_min: int = 40
## Hitstun berkurang sekian frame untuk tiap pukulan lanjutan, supaya tidak ada kombo tanpa akhir.
@export var hitstun_decay: int = 1
@export var hitstun_min: int = 6

@export_group("Jatuh dan dorongan")
## Lama tergeletak setelah dijatuhkan.
@export var knockdown_frames: int = 34
@export var getup_frames: int = 12
## Persen kecepatan dorongan yang tersisa tiap frame.
@export var pushback_friction: int = 82
## Hitstop tambahan pada pukulan K.O.
@export var ko_hitstop: int = 22
## Lama kilatan putih pada petarung yang kena.
@export var hit_flash_frames: int = 4
## Jarak maksimum antar petarung supaya keduanya tetap di layar (piksel).
@export var max_distance: int = 400
## Jarak minimum dari tepi stage (piksel).
@export var stage_margin: int = 18
