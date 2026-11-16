import Base
import ../base/num.bend as N

type Fa is Data:
  Fa{ m: String, v: List<&2, F64> }

def fas() -> List<&2, Fa>:
  [Fa{"M1.6", [1.6f64, 0.35f64, 1.7f64, 1.8f64, 2.0f64, 1.25f64, 3.14f64, 1.6f64, 3.5f64, 1.8f64, F64.nan(), F64.nan(), F64.nan(), 3.2f64]},
   Fa{"M2", [2.0f64, 0.4f64, 2.2f64, 2.4f64, 2.6f64, 1.6f64, 3.98f64, 2.0f64, 4.4f64, 2.2f64, F64.nan(), F64.nan(), F64.nan(), 4.0f64]},
   Fa{"M2.5", [2.5f64, 0.45f64, 2.7f64, 2.9f64, 3.1f64, 2.05f64, 4.68f64, 2.5f64, 5.5f64, 3.0f64, F64.nan(), F64.nan(), F64.nan(), 5.0f64]},
   Fa{"M3", [3.0f64, 0.5f64, 3.2f64, 3.4f64, 3.6f64, 2.5f64, 5.68f64, 3.0f64, 6.5f64, 3.5f64, 6.72f64, 1.86f64, 6.94f64, 5.5f64]},
   Fa{"M4", [4.0f64, 0.7f64, 4.3f64, 4.5f64, 4.8f64, 3.3f64, 7.22f64, 4.0f64, 8.0f64, 4.8f64, 8.96f64, 2.48f64, 9.18f64, 7.0f64]},
   Fa{"M5", [5.0f64, 0.8f64, 5.3f64, 5.5f64, 5.8f64, 4.2f64, 8.72f64, 5.0f64, 10.0f64, 5.8f64, 11.2f64, 3.1f64, 11.47f64, 8.0f64]},
   Fa{"M6", [6.0f64, 1.0f64, 6.4f64, 6.6f64, 7.0f64, 5.0f64, 10.22f64, 6.0f64, 11.0f64, 6.8f64, 13.44f64, 3.72f64, 13.71f64, 10.0f64]},
   Fa{"M8", [8.0f64, 1.25f64, 8.4f64, 9.0f64, 10.0f64, 6.8f64, 13.27f64, 8.0f64, 15.0f64, 8.8f64, 17.92f64, 4.96f64, 18.25f64, 13.0f64]},
   Fa{"M10", [10.0f64, 1.5f64, 10.5f64, 11.0f64, 12.0f64, 8.5f64, 16.27f64, 10.0f64, 18.0f64, 10.8f64, 22.4f64, 6.2f64, 22.73f64, 16.0f64]},
   Fa{"M12", [12.0f64, 1.75f64, 13.0f64, 13.5f64, 14.5f64, 10.2f64, 18.27f64, 12.0f64, 20.0f64, 12.8f64, 26.88f64, 7.44f64, 27.21f64, 18.0f64]},
   Fa{"M16", [16.0f64, 2.0f64, 17.0f64, 17.5f64, 18.5f64, 14.0f64, 24.0f64, 16.0f64, 26.0f64, 16.8f64, 33.6f64, 8.8f64, 33.99f64, 24.0f64]},
   Fa{"M20", [20.0f64, 2.5f64, 21.0f64, 22.0f64, 24.0f64, 17.5f64, 30.33f64, 20.0f64, 33.0f64, 21.0f64, 40.32f64, 10.16f64, 40.71f64, 30.0f64]}]

def fa_go(xs: List<&2, Fa>, +m: String) -> Fa:
  match xs:
    case []: Fa{"", []}
    case +h <> +t:
      Fa{+hm, +hv} = h
      Bool.pick(Fa, String.eq(hm, m), Fa{hm, hv}, fa_go(t, m))

def fa(+m: String) -> Fa:
  fa_go(fas(), m)

def fa_m(+a: Fa) -> String:
  Fa{+k, v} = a
  k

def fa_ok(+m: String) -> Bool:
  Bool.not(String.is_empty(fa_m(fa(m))))

def fv_go(xs: List<&2, F64>, +i: Nat) -> F64:
  match xs:
    case []: F64.nan()
    case +h <> +t:
      match i:
        case 0n: h
        case 1n+j: fv_go(t, j)

def fv(+a: Fa, +i: Nat) -> F64:
  Fa{m, +v} = a
  fv_go(v, i)

def d(+m: String) -> F64:
  fv(fa(m), 0n)

def p(+m: String) -> F64:
  fv(fa(m), 1n)

def clear_fine(+m: String) -> F64:
  fv(fa(m), 2n)

def clear_medium(+m: String) -> F64:
  fv(fa(m), 3n)

def clear_coarse(+m: String) -> F64:
  fv(fa(m), 4n)

def tap_drill(+m: String) -> F64:
  fv(fa(m), 5n)

def shcs_dk(+m: String) -> F64:
  fv(fa(m), 6n)

def shcs_k(+m: String) -> F64:
  fv(fa(m), 7n)

def cbore_d(+m: String) -> F64:
  fv(fa(m), 8n)

def cbore_t(+m: String) -> F64:
  fv(fa(m), 9n)

def csk_dk(+m: String) -> F64:
  fv(fa(m), 10n)

def csk_k(+m: String) -> F64:
  fv(fa(m), 11n)

def csk_d(+m: String) -> F64:
  fv(fa(m), 12n)

def hex_af(+m: String) -> F64:
  fv(fa(m), 13n)

def sizes() -> String:
  "M1.6 M2 M2.5 M3 M4 M5 M6 M8 M10 M12 M16 M20"

def sw_go(xs: List<&2, Fa>, +i: Nat) -> String:
  match xs:
    case []: ""
    case +h <> +t:
      Fa{+hm, +hv} = h
      +r = sw_go(t, i)
      +v = fv_go(hv, i)
      Bool.pick(String, F64.is_eq(v, v), Bool.pick(String, String.is_empty(r), hm, hm ++ " " ++ r), r)

def sizes_with(+i: Nat) -> String:
  sw_go(fas(), i)

def cite(+t: String) -> String:
  Bool.pick(String, String.eq(t, "clear"), "ISO 273:1979 clearance holes, fine H12 / medium H13 / coarse H14 | source: engineersbible.com/counterbore-socket-iso (ISO 273 series columns)", Bool.pick(String, String.eq(t, "tap"), "HSS machine taps, DIN 371 / DIN 376 shank, metric coarse thread: nominal band [d_lo, d_hi], rated thread depth as a multiple of the nominal diameter for through holes (kt, 0 = no through-hole tap held) and blind holes (kb) | source: Hoffmann Group: HOLEX Clever Tap Form B 131265 (spiral point, M3 to M24, through holes to 3xD, blind holes to 2xD), hoffmann-group.com/US/en/hus/p/131265-M3; GARANT machine tap 134200 (M2 to M10, blind holes to 3xD), hoffmann-group.com/US/en/hus/p/134200-M3", Bool.pick(String, String.eq(t, "shcs"), "ISO 4762 hexagon socket head cap screw, dk max (knurled head) and k max | source: westfieldfasteners.co.uk/Standards/ScrewBolt-SHCap-M.html", Bool.pick(String, String.eq(t, "cbore"), "DIN 974-1:2008 counterbore diameter for ISO 4762 without washer; depth k + allowance | source: engineersbible.com/counterbore-socket-iso", Bool.pick(String, String.eq(t, "cskh"), "ISO 10642 hexagon socket countersunk head screw, dk theoretical max and k max, 90 degree head | source: westfieldfasteners.co.uk/Standards/ScrewBolt-SHCsk-M.html", Bool.pick(String, String.eq(t, "csk"), "DIN 74 form F / ISO 15065 90 degree countersink for ISO 10642 | source: engineersbible.com countersunk-iso table, reproduced at xometry.com/resources/machining/what-are-countersink-holes", Bool.pick(String, String.eq(t, "hex"), "ISO 4032 hexagon nut width across flats s (ISO 272) | source: ISO 4032 s nominal", Bool.pick(String, String.eq(t, "ring_shaft"), "DIN 471:2011 retaining rings for shafts, normal type: ring s, groove diameter d2, groove width m, edge margin n min | source: fasten.it/en/Norms/Norm/DIN 471 (the d1 = 3 width is printed 05 there; read as 0.5)", Bool.pick(String, String.eq(t, "ring_bore"), "DIN 472:2011 retaining rings for bores, normal type: ring s, groove diameter d2, groove width m, edge margin n min | source: fasten.it/en/Norms/Norm/DIN 472", Bool.pick(String, String.eq(t, "key"), "DIN 6885-1 parallel keys and keyways: shaft diameter over d_lo up to d_hi, key b x h, shaft keyway depth t1, hub keyway depth t2 | source: fasten.it/en/norms/norm/din_6885-1 (1968 table)", Bool.pick(String, String.eq(t, "drill"), "ISO 235 / DIN 338 RN / BS 328 parallel shank jobber drills, 118 degree point: diameter band (d_lo, d_hi] and flute length l2; the metric series is every 0.1 mm from 1.0 to 13.9 and every 0.25 mm from 14.0 to 16.0 | source: Dormer A002 catalogue page (DIN 338 RN / BS 328 / ISO 235), static.chipdip.ru/lib/996/DOC027996834.pdf, every listed size from 1.00 to 16.00 mm; series steps after BS 328 as summarised at en.wikipedia.org/wiki/Drill_bit_sizes", Bool.pick(String, String.eq(t, "endmill"), "solid carbide flat end mill, dimensions after DIN 6527 L: cutter diameter dc, cutting edge length lc, overall length l1, shank diameter ds | source: Hoffmann Group HOLEX article 202277 (one product page per diameter), hoffmann-group.com/US/en/hus/p/202277-<dc>", Bool.pick(String, String.eq(t, "csink"), "DIN 335 C 90 degree HSS countersink: outer diameter d1 and shank ds; a countersink cuts any 90 degree seat up to d1 | source: PFERD HSS countersink DIN 335 C 90 degree range, br.pferd.com/en/hss-countersink-din-335-c-90 (items 25202100 to 25202121)", Bool.pick(String, String.eq(t, "groove_insert"), "DIN 471 external partial-profile grooving insert, groove width m (H13), one insert per width; a wider groove takes several plunges of the widest insert that fits | source: Hoffmann Group GARANT 271005 (DIN 471 external, widths 0.5, 0.7, 0.8, 0.9, 1.1, 1.3, 1.6, 1.85, 2.15, 2.65), hoffmann-group.com/p/271005", Bool.pick(String, String.eq(t, "thread_insert"), "16ER ISO metric full-profile external threading insert, 60 degree, one insert per pitch p | source: shop.butlerbros.com 16ER ... ISO listings (pitches 0.70, 0.75, 0.80, 1.00, 1.50, 1.75, 3.00); kramp.com Huvema DSW16ERISO series, 1.00 to 3.00 in 0.25 steps", Bool.pick(String, String.eq(t, "endmill_reach"), "solid carbide flat end mill with a neck: cutter diameter dc, cutting edge length lc, usable length l1 (reach under the neck), neck diameter d1, shank ds, machining group grp (1 = N non-ferrous and O other only, 2 = P steel, M stainless, K cast iron); the neck is narrower than the cutter, so a wall or floor down to l1 is cut in axial steps of at most lc | source: Hoffmann Group GARANT 202247 (solid carbide MTC end mill, long reach, uncoated, N/O), hoffmann-group.com/US/en/hus/p/202247-<dc>; GARANT Master Steel SlotMachine 205556 (TiAlN, long neck, P/M/K), hoffmann-group.com/US/en/hus/p/205556-<dc>; dc, lc, D1 and L1 read from each product page", Bool.pick(String, String.eq(t, "bore_bar"), "steel boring bar A..SCLCR 95 degree for CC.. inserts, helical flutes: shank diameter ds, minimum bore dmin, overall length l, head length l1 | source: Hoffmann Group GARANT Master Turn 260030 (A08H, A10K, A12L SCLCR06; A16Q, A20R SCLCR09; A25R SCLCR12), hoffmann-group.com/GR/el/pangakis/p/260030-<ds>%402F<insert>; Hole diameter min. D1 from each product page", Bool.pick(String, String.eq(t, "bar_overhang"), "maximum tool overhang of a steel boring bar as a multiple of the bar diameter BD, for turning, grooving and threading | source: Sandvik Coromant, General turning: tool set-up, sandvik.coromant.com/en-gb/knowledge/general-turning/tool-set-up (steel bars 4 x BD turning, 3 x BD grooving and threading; carbide 6 and 5 and damped 7 to 14 are not held)", Bool.pick(String, String.eq(t, "igroove_insert"), "solid carbide micro grooving insert, internal, square profile: minimum bore dmin, insert width w, maximum radial cutting depth ap, usable length l1 from the bore mouth | source: Hoffmann Group GARANT 270314 4,2/1 (micro grooving insert, internal, right-hand, L1 = 20 mm), hoffmann-group.com/US/en/hus/p/270314-4%2C2@2F1", Bool.pick(String, String.eq(t, "fgroove_tool"), "axial (face) grooving cutting head: smallest and largest groove diameter of the first plunge d1 and d2, insert width w, maximum groove depth tmax; a wider groove takes several plunges | source: Hoffmann Group GARANT 273823 (Schneidentraeger konkav fuer Planeinstich, links), hoffmann-group.com/p/273823-<d1>%402F<d2>, variants 26/41, 38/55, 52/72, 67/100 and 90/130 read from their product pages", ""))))))))))))))))))))

def table_of(+c: String) -> String:
  Bool.pick(String, String.eq(c, "clear_fine"), "clear", Bool.pick(String, String.eq(c, "clear_medium"), "clear", Bool.pick(String, String.eq(c, "clear_coarse"), "clear", Bool.pick(String, String.eq(c, "shcs_dk"), "shcs", Bool.pick(String, String.eq(c, "shcs_k"), "shcs", Bool.pick(String, String.eq(c, "cbore_d"), "cbore", Bool.pick(String, String.eq(c, "cbore_t"), "cbore", Bool.pick(String, String.eq(c, "csk_dk"), "cskh", Bool.pick(String, String.eq(c, "csk_k"), "cskh", Bool.pick(String, String.eq(c, "csk_d"), "csk", Bool.pick(String, String.eq(c, "hex_af"), "hex", "")))))))))))

def t_ring_shaft() -> List<&2, List<&2, F64>>:
  [[3.0f64, 0.4f64, 2.8f64, 0.5f64, 0.3f64],
   [4.0f64, 0.4f64, 3.8f64, 0.5f64, 0.3f64],
   [5.0f64, 0.6f64, 4.8f64, 0.7f64, 0.3f64],
   [6.0f64, 0.7f64, 5.7f64, 0.8f64, 0.5f64],
   [7.0f64, 0.8f64, 6.7f64, 0.9f64, 0.5f64],
   [8.0f64, 0.8f64, 7.6f64, 0.9f64, 0.6f64],
   [9.0f64, 1.0f64, 8.6f64, 1.1f64, 0.6f64],
   [10.0f64, 1.0f64, 9.6f64, 1.1f64, 0.6f64],
   [11.0f64, 1.0f64, 10.5f64, 1.1f64, 0.8f64],
   [12.0f64, 1.0f64, 11.5f64, 1.1f64, 0.8f64],
   [13.0f64, 1.0f64, 12.4f64, 1.1f64, 0.9f64],
   [14.0f64, 1.0f64, 13.4f64, 1.1f64, 0.9f64],
   [15.0f64, 1.0f64, 14.3f64, 1.1f64, 1.1f64],
   [16.0f64, 1.0f64, 15.2f64, 1.1f64, 1.2f64],
   [17.0f64, 1.0f64, 16.2f64, 1.1f64, 1.2f64],
   [18.0f64, 1.2f64, 17.0f64, 1.3f64, 1.5f64],
   [19.0f64, 1.2f64, 18.0f64, 1.3f64, 1.5f64],
   [20.0f64, 1.2f64, 19.0f64, 1.3f64, 1.5f64],
   [21.0f64, 1.2f64, 20.0f64, 1.3f64, 1.5f64],
   [22.0f64, 1.2f64, 21.0f64, 1.3f64, 1.5f64],
   [24.0f64, 1.2f64, 22.9f64, 1.3f64, 1.7f64],
   [25.0f64, 1.2f64, 23.9f64, 1.3f64, 1.7f64],
   [26.0f64, 1.2f64, 24.9f64, 1.3f64, 1.7f64],
   [28.0f64, 1.5f64, 26.6f64, 1.6f64, 2.1f64],
   [29.0f64, 1.5f64, 27.6f64, 1.6f64, 2.1f64],
   [30.0f64, 1.5f64, 28.6f64, 1.6f64, 2.1f64]]

def t_ring_bore() -> List<&2, List<&2, F64>>:
  [[8.0f64, 0.8f64, 8.4f64, 0.9f64, 0.6f64],
   [9.0f64, 0.8f64, 9.4f64, 0.9f64, 0.6f64],
   [10.0f64, 1.0f64, 10.4f64, 1.1f64, 0.6f64],
   [11.0f64, 1.0f64, 11.4f64, 1.1f64, 0.6f64],
   [12.0f64, 1.0f64, 12.5f64, 1.1f64, 0.8f64],
   [13.0f64, 1.0f64, 13.6f64, 1.1f64, 0.9f64],
   [14.0f64, 1.0f64, 14.6f64, 1.1f64, 0.9f64],
   [15.0f64, 1.0f64, 15.7f64, 1.1f64, 1.1f64],
   [16.0f64, 1.0f64, 16.8f64, 1.1f64, 1.2f64],
   [17.0f64, 1.0f64, 17.8f64, 1.1f64, 1.2f64],
   [18.0f64, 1.0f64, 19.0f64, 1.1f64, 1.5f64],
   [19.0f64, 1.0f64, 20.0f64, 1.1f64, 1.5f64],
   [20.0f64, 1.0f64, 21.0f64, 1.1f64, 1.5f64],
   [21.0f64, 1.0f64, 22.0f64, 1.1f64, 1.5f64],
   [22.0f64, 1.0f64, 23.0f64, 1.1f64, 1.5f64],
   [24.0f64, 1.2f64, 25.2f64, 1.3f64, 1.8f64],
   [25.0f64, 1.2f64, 26.2f64, 1.3f64, 1.8f64],
   [26.0f64, 1.2f64, 27.2f64, 1.3f64, 1.8f64],
   [28.0f64, 1.2f64, 29.4f64, 1.3f64, 2.1f64],
   [30.0f64, 1.2f64, 31.4f64, 1.3f64, 2.1f64],
   [31.0f64, 1.2f64, 32.7f64, 1.3f64, 2.6f64],
   [32.0f64, 1.2f64, 33.7f64, 1.3f64, 2.6f64],
   [34.0f64, 1.5f64, 35.7f64, 1.6f64, 2.6f64],
   [35.0f64, 1.5f64, 37.0f64, 1.6f64, 3.0f64],
   [36.0f64, 1.5f64, 38.0f64, 1.6f64, 3.0f64],
   [37.0f64, 1.5f64, 39.0f64, 1.6f64, 3.0f64],
   [38.0f64, 1.5f64, 40.0f64, 1.6f64, 3.0f64],
   [40.0f64, 1.75f64, 42.5f64, 1.85f64, 3.8f64]]

def t_key() -> List<&2, List<&2, F64>>:
  [[6.0f64, 8.0f64, 2.0f64, 2.0f64, 1.2f64, 1.0f64],
   [8.0f64, 10.0f64, 3.0f64, 3.0f64, 1.8f64, 1.4f64],
   [10.0f64, 12.0f64, 4.0f64, 4.0f64, 2.5f64, 1.8f64],
   [12.0f64, 17.0f64, 5.0f64, 5.0f64, 3.0f64, 2.3f64],
   [17.0f64, 22.0f64, 6.0f64, 6.0f64, 3.5f64, 2.8f64],
   [22.0f64, 30.0f64, 8.0f64, 7.0f64, 4.0f64, 3.3f64],
   [30.0f64, 38.0f64, 10.0f64, 8.0f64, 5.0f64, 3.3f64],
   [38.0f64, 44.0f64, 12.0f64, 8.0f64, 5.0f64, 3.3f64],
   [44.0f64, 50.0f64, 14.0f64, 9.0f64, 5.5f64, 3.8f64]]

def t_drill() -> List<&2, List<&2, F64>>:
  [[0.95f64, 1.06f64, 12.0f64],
   [1.06f64, 1.18f64, 14.0f64],
   [1.18f64, 1.32f64, 16.0f64],
   [1.32f64, 1.5f64, 18.0f64],
   [1.5f64, 1.7f64, 20.0f64],
   [1.7f64, 1.9f64, 22.0f64],
   [1.9f64, 2.12f64, 24.0f64],
   [2.12f64, 2.36f64, 27.0f64],
   [2.36f64, 2.65f64, 30.0f64],
   [2.65f64, 3.0f64, 33.0f64],
   [3.0f64, 3.35f64, 36.0f64],
   [3.35f64, 3.75f64, 39.0f64],
   [3.75f64, 4.25f64, 43.0f64],
   [4.25f64, 4.75f64, 47.0f64],
   [4.75f64, 5.3f64, 52.0f64],
   [5.3f64, 6.0f64, 57.0f64],
   [6.0f64, 6.7f64, 63.0f64],
   [6.7f64, 7.5f64, 69.0f64],
   [7.5f64, 8.5f64, 75.0f64],
   [8.5f64, 9.5f64, 81.0f64],
   [9.5f64, 10.6f64, 87.0f64],
   [10.6f64, 11.8f64, 94.0f64],
   [11.8f64, 13.2f64, 101.0f64],
   [13.2f64, 14.0f64, 108.0f64],
   [14.0f64, 15.0f64, 114.0f64],
   [15.0f64, 16.0f64, 120.0f64]]

def t_endmill() -> List<&2, List<&2, F64>>:
  [[1.0f64, 3.0f64, 50.0f64, 3.0f64],
   [1.5f64, 4.0f64, 50.0f64, 3.0f64],
   [2.0f64, 5.0f64, 50.0f64, 3.0f64],
   [2.5f64, 6.0f64, 50.0f64, 6.0f64],
   [3.0f64, 8.0f64, 57.0f64, 6.0f64],
   [4.0f64, 11.0f64, 57.0f64, 6.0f64],
   [5.0f64, 13.0f64, 57.0f64, 6.0f64],
   [6.0f64, 13.0f64, 57.0f64, 6.0f64],
   [8.0f64, 19.0f64, 63.0f64, 8.0f64],
   [10.0f64, 22.0f64, 72.0f64, 10.0f64],
   [12.0f64, 26.0f64, 83.0f64, 12.0f64],
   [16.0f64, 32.0f64, 92.0f64, 16.0f64],
   [20.0f64, 38.0f64, 104.0f64, 20.0f64]]

def t_csink() -> List<&2, List<&2, F64>>:
  [[4.3f64, 4.0f64],
   [5.0f64, 4.0f64],
   [6.0f64, 5.0f64],
   [6.3f64, 5.0f64],
   [7.0f64, 6.0f64],
   [8.0f64, 6.0f64],
   [8.3f64, 6.0f64],
   [10.0f64, 6.0f64],
   [10.4f64, 6.0f64],
   [11.5f64, 8.0f64],
   [12.4f64, 8.0f64],
   [15.0f64, 10.0f64],
   [16.5f64, 10.0f64],
   [19.0f64, 10.0f64],
   [20.5f64, 10.0f64],
   [25.0f64, 10.0f64],
   [28.0f64, 12.0f64],
   [31.0f64, 12.0f64],
   [37.0f64, 12.0f64],
   [40.0f64, 15.0f64]]

def t_tap() -> List<&2, List<&2, F64>>:
  [[1.95f64, 2.55f64, 0.0f64, 3.0f64],
   [2.95f64, 10.05f64, 3.0f64, 3.0f64],
   [11.95f64, 24.05f64, 3.0f64, 2.0f64]]

def t_groove_insert() -> List<&2, List<&2, F64>>:
  [[0.5f64],
   [0.7f64],
   [0.8f64],
   [0.9f64],
   [1.1f64],
   [1.3f64],
   [1.6f64],
   [1.85f64],
   [2.15f64],
   [2.65f64]]

def t_thread_insert() -> List<&2, List<&2, F64>>:
  [[0.7f64],
   [0.75f64],
   [0.8f64],
   [1.0f64],
   [1.25f64],
   [1.5f64],
   [1.75f64],
   [2.0f64],
   [2.25f64],
   [2.5f64],
   [2.75f64],
   [3.0f64]]

def t_endmill_reach() -> List<&2, List<&2, F64>>:
  [[4.0f64, 6.5f64, 24.0f64, 3.7f64, 6.0f64, 1.0f64],
   [5.0f64, 8.0f64, 30.0f64, 4.7f64, 6.0f64, 1.0f64],
   [6.0f64, 10.0f64, 42.0f64, 5.7f64, 6.0f64, 1.0f64],
   [6.0f64, 13.0f64, 42.0f64, 5.4f64, 6.0f64, 2.0f64],
   [8.0f64, 13.0f64, 62.0f64, 7.4f64, 8.0f64, 1.0f64],
   [8.0f64, 21.0f64, 62.0f64, 7.2f64, 8.0f64, 2.0f64],
   [10.0f64, 16.0f64, 58.0f64, 9.2f64, 10.0f64, 1.0f64],
   [10.0f64, 22.0f64, 58.0f64, 9.0f64, 10.0f64, 2.0f64],
   [12.0f64, 19.0f64, 73.0f64, 11.0f64, 12.0f64, 1.0f64],
   [12.0f64, 26.0f64, 73.0f64, 10.8f64, 12.0f64, 2.0f64],
   [16.0f64, 25.0f64, 100.0f64, 15.0f64, 16.0f64, 1.0f64],
   [16.0f64, 36.0f64, 100.0f64, 14.4f64, 16.0f64, 2.0f64],
   [20.0f64, 32.0f64, 98.0f64, 19.0f64, 20.0f64, 1.0f64],
   [20.0f64, 41.0f64, 98.0f64, 18.0f64, 20.0f64, 2.0f64]]

def t_bore_bar() -> List<&2, List<&2, F64>>:
  [[8.0f64, 10.0f64, 100.0f64, 20.0f64],
   [10.0f64, 12.0f64, 125.0f64, 20.0f64],
   [12.0f64, 14.0f64, 140.0f64, 24.3f64],
   [16.0f64, 18.0f64, 180.0f64, 31.0f64],
   [20.0f64, 22.0f64, 200.0f64, 36.0f64],
   [25.0f64, 27.0f64, 200.0f64, 43.0f64]]

def t_bar_overhang() -> List<&2, List<&2, F64>>:
  [[4.0f64, 3.0f64, 3.0f64]]

def t_igroove_insert() -> List<&2, List<&2, F64>>:
  [[4.2f64, 1.0f64, 0.8f64, 20.0f64]]

def t_fgroove_tool() -> List<&2, List<&2, F64>>:
  [[26.0f64, 41.0f64, 4.0f64, 15.0f64],
   [38.0f64, 55.0f64, 4.0f64, 15.0f64],
   [52.0f64, 72.0f64, 4.0f64, 15.0f64],
   [67.0f64, 100.0f64, 4.0f64, 15.0f64],
   [90.0f64, 130.0f64, 4.0f64, 15.0f64]]

def tab(+t: String) -> List<&2, List<&2, F64>>:
  Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "ring_shaft"), t_ring_shaft(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "ring_bore"), t_ring_bore(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "key"), t_key(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "drill"), t_drill(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "endmill"), t_endmill(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "csink"), t_csink(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "tap"), t_tap(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "groove_insert"), t_groove_insert(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "thread_insert"), t_thread_insert(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "endmill_reach"), t_endmill_reach(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "bore_bar"), t_bore_bar(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "bar_overhang"), t_bar_overhang(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "igroove_insert"), t_igroove_insert(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "fgroove_tool"), t_fgroove_tool(), []))))))))))))))

def row_go(rs: List<&2, List<&2, F64>>, +key: Bool, +d: F64) -> List<&2, F64>:
  match rs:
    case []: []
    case +r <> +t:
      +a = fv_go(r, 0n)
      +b = fv_go(r, 1n)
      +hit = Bool.pick(Bool, key, Bool.and(F64.is_lt(a, d), F64.is_le(d, F64.add(b, 1.0e-9f64))), F64.is_le(F64.abs(F64.sub(a, d)), 1.0e-9f64))
      Bool.pick(List<&2, F64>, hit, r, row_go(t, key, d))

def row(+t: String, +d: F64) -> List<&2, F64>:
  row_go(tab(t), Bool.or(String.eq(t, "key"), Bool.or(String.eq(t, "drill"), String.eq(t, "tap"))), d)

def row_ok(+r: List<&2, F64>) -> Bool:
  Bool.not(Nat.is_eq(List.length(&2, F64, r), 0n))

def rk_go(rs: List<&2, List<&2, F64>>, +key: Bool) -> String:
  match rs:
    case []: ""
    case +r <> +t:
      +s = Bool.pick(String, key, N.f_show(fv_go(r, 0n)) ++ "-" ++ N.f_show(fv_go(r, 1n)), N.f_show(fv_go(r, 0n)))
      +rest = rk_go(t, key)
      Bool.pick(String, String.is_empty(rest), s, s ++ " " ++ rest)

def row_keys(+t: String) -> String:
  rk_go(tab(t), Bool.or(String.eq(t, "key"), Bool.or(String.eq(t, "drill"), String.eq(t, "tap"))))
