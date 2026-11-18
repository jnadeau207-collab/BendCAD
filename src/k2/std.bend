import Base
import ../base/num.bend as N

type Fa is Data:
  Fa{ m: String, v: List<&2, F64> }

def fas() -> List<&2, Fa>:
  [Fa{"M1.6", [1.6f64, 0.35f64, 1.7f64, 1.8f64, 2.0f64, 1.25f64, 3.14f64, 1.6f64, 3.5f64, 1.8f64, F64.nan(), F64.nan(), F64.nan(), 3.2f64, 1.5f64, 0.7f64, 15.0f64]},
   Fa{"M2", [2.0f64, 0.4f64, 2.2f64, 2.4f64, 2.6f64, 1.6f64, 3.98f64, 2.0f64, 4.4f64, 2.2f64, F64.nan(), F64.nan(), F64.nan(), 4.0f64, 1.5f64, 1.0f64, 16.0f64]},
   Fa{"M2.5", [2.5f64, 0.45f64, 2.7f64, 2.9f64, 3.1f64, 2.05f64, 4.68f64, 2.5f64, 5.5f64, 3.0f64, F64.nan(), F64.nan(), F64.nan(), 5.0f64, 2.0f64, 1.1f64, 17.0f64]},
   Fa{"M3", [3.0f64, 0.5f64, 3.2f64, 3.4f64, 3.6f64, 2.5f64, 5.68f64, 3.0f64, 6.5f64, 3.5f64, 6.72f64, 1.86f64, 6.94f64, 5.5f64, 2.5f64, 1.3f64, 18.0f64]},
   Fa{"M4", [4.0f64, 0.7f64, 4.3f64, 4.5f64, 4.8f64, 3.3f64, 7.22f64, 4.0f64, 8.0f64, 4.8f64, 8.96f64, 2.48f64, 9.18f64, 7.0f64, 3.0f64, 2.0f64, 20.0f64]},
   Fa{"M5", [5.0f64, 0.8f64, 5.3f64, 5.5f64, 5.8f64, 4.2f64, 8.72f64, 5.0f64, 10.0f64, 5.8f64, 11.2f64, 3.1f64, 11.47f64, 8.0f64, 4.0f64, 2.5f64, 22.0f64]},
   Fa{"M6", [6.0f64, 1.0f64, 6.4f64, 6.6f64, 7.0f64, 5.0f64, 10.22f64, 6.0f64, 11.0f64, 6.8f64, 13.44f64, 3.72f64, 13.71f64, 10.0f64, 5.0f64, 3.0f64, 24.0f64]},
   Fa{"M8", [8.0f64, 1.25f64, 8.4f64, 9.0f64, 10.0f64, 6.8f64, 13.27f64, 8.0f64, 15.0f64, 8.8f64, 17.92f64, 4.96f64, 18.25f64, 13.0f64, 6.0f64, 4.0f64, 28.0f64]},
   Fa{"M10", [10.0f64, 1.5f64, 10.5f64, 11.0f64, 12.0f64, 8.5f64, 16.27f64, 10.0f64, 18.0f64, 10.8f64, 22.4f64, 6.2f64, 22.73f64, 16.0f64, 8.0f64, 5.0f64, 32.0f64]},
   Fa{"M12", [12.0f64, 1.75f64, 13.0f64, 13.5f64, 14.5f64, 10.2f64, 18.27f64, 12.0f64, 20.0f64, 12.8f64, 26.88f64, 7.44f64, 27.21f64, 18.0f64, 10.0f64, 6.0f64, 36.0f64]},
   Fa{"M16", [16.0f64, 2.0f64, 17.0f64, 17.5f64, 18.5f64, 14.0f64, 24.0f64, 16.0f64, 26.0f64, 16.8f64, 33.6f64, 8.8f64, 33.99f64, 24.0f64, 14.0f64, 8.0f64, 44.0f64]},
   Fa{"M20", [20.0f64, 2.5f64, 21.0f64, 22.0f64, 24.0f64, 17.5f64, 30.33f64, 20.0f64, 33.0f64, 21.0f64, 40.32f64, 10.16f64, 40.71f64, 30.0f64, 17.0f64, 10.0f64, 52.0f64]}]

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

def shcs_s(+m: String) -> F64:
  fv(fa(m), 14n)

def shcs_t(+m: String) -> F64:
  fv(fa(m), 15n)

def shcs_b(+m: String) -> F64:
  fv(fa(m), 16n)

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
  Bool.pick(String, String.eq(t, "clear"), "ISO 273:1979 clearance holes, fine H12 / medium H13 / coarse H14 | source: engineersbible.com/counterbore-socket-iso (ISO 273 series columns)", Bool.pick(String, String.eq(t, "tap"), "HSS machine taps, DIN 371 / DIN 376 shank, metric coarse thread: nominal band [d_lo, d_hi], rated thread depth as a multiple of the nominal diameter for through holes (kt, 0 = no through-hole tap held) and blind holes (kb) | source: Hoffmann Group: HOLEX Clever Tap Form B 131265 (spiral point, M3 to M24, through holes to 3xD, blind holes to 2xD), hoffmann-group.com/US/en/hus/p/131265-M3; GARANT machine tap 134200 (M2 to M10, blind holes to 3xD), hoffmann-group.com/US/en/hus/p/134200-M3", Bool.pick(String, String.eq(t, "shcs"), "ISO 4762 hexagon socket head cap screw: dk max (knurled head), k max, socket s nominal, socket depth t min and thread length b (reference) | source: westfieldfasteners.co.uk/Standards/ScrewBolt-SHCap-M.html", Bool.pick(String, String.eq(t, "cbore"), "DIN 974-1:2008 counterbore diameter for ISO 4762 without washer; depth k + allowance | source: engineersbible.com/counterbore-socket-iso", Bool.pick(String, String.eq(t, "cskh"), "ISO 10642 hexagon socket countersunk head screw, dk theoretical max and k max, 90 degree head | source: westfieldfasteners.co.uk/Standards/ScrewBolt-SHCsk-M.html", Bool.pick(String, String.eq(t, "csk"), "DIN 74 form F / ISO 15065 90 degree countersink for ISO 10642 | source: engineersbible.com countersunk-iso table, reproduced at xometry.com/resources/machining/what-are-countersink-holes", Bool.pick(String, String.eq(t, "hex"), "ISO 4032 hexagon nut width across flats s (ISO 272) | source: ISO 4032 s nominal", Bool.pick(String, String.eq(t, "ring_shaft"), "DIN 471:2011 retaining rings for shafts, normal type: ring s, groove diameter d2, groove width m, edge margin n min | source: fasten.it/en/Norms/Norm/DIN 471 (the d1 = 3 width is printed 05 there; read as 0.5)", Bool.pick(String, String.eq(t, "ring_bore"), "DIN 472:2011 retaining rings for bores, normal type: ring s, groove diameter d2, groove width m, edge margin n min | source: fasten.it/en/Norms/Norm/DIN 472", Bool.pick(String, String.eq(t, "key"), "DIN 6885-1 parallel keys and keyways: shaft diameter over d_lo up to d_hi, key b x h, shaft keyway depth t1, hub keyway depth t2 | source: fasten.it/en/norms/norm/din_6885-1 (1968 table)", Bool.pick(String, String.eq(t, "drill"), "ISO 235 / DIN 338 RN / BS 328 parallel shank jobber drills, 118 degree point: diameter band (d_lo, d_hi] and flute length l2; the metric series is every 0.1 mm from 1.0 to 13.9 and every 0.25 mm from 14.0 to 16.0 | source: Dormer A002 catalogue page (DIN 338 RN / BS 328 / ISO 235), static.chipdip.ru/lib/996/DOC027996834.pdf, every listed size from 1.00 to 16.00 mm; series steps after BS 328 as summarised at en.wikipedia.org/wiki/Drill_bit_sizes", Bool.pick(String, String.eq(t, "endmill"), "solid carbide flat end mill, dimensions after DIN 6527 L: cutter diameter dc, cutting edge length lc, overall length l1, shank diameter ds | source: Hoffmann Group HOLEX article 202277 (one product page per diameter), hoffmann-group.com/US/en/hus/p/202277-<dc>", Bool.pick(String, String.eq(t, "csink"), "DIN 335 C 90 degree HSS countersink: outer diameter d1 and shank ds; a countersink cuts any 90 degree seat up to d1 | source: PFERD HSS countersink DIN 335 C 90 degree range, br.pferd.com/en/hss-countersink-din-335-c-90 (items 25202100 to 25202121)", Bool.pick(String, String.eq(t, "groove_insert"), "DIN 471 external partial-profile grooving insert, groove width m (H13), one insert per width; a wider groove takes several plunges of the widest insert that fits | source: Hoffmann Group GARANT 271005 (DIN 471 external, widths 0.5, 0.7, 0.8, 0.9, 1.1, 1.3, 1.6, 1.85, 2.15, 2.65), hoffmann-group.com/p/271005", Bool.pick(String, String.eq(t, "thread_insert"), "16ER ISO metric full-profile external threading insert, 60 degree, one insert per pitch p | source: shop.butlerbros.com 16ER ... ISO listings (pitches 0.70, 0.75, 0.80, 1.00, 1.50, 1.75, 3.00); kramp.com Huvema DSW16ERISO series, 1.00 to 3.00 in 0.25 steps", Bool.pick(String, String.eq(t, "endmill_reach"), "solid carbide flat end mill with a neck: cutter diameter dc, cutting edge length lc, usable length l1 (reach under the neck), neck diameter d1, shank ds, machining group grp (1 = N non-ferrous and O other only, 2 = P steel, M stainless, K cast iron); the neck is narrower than the cutter, so a wall or floor down to l1 is cut in axial steps of at most lc | source: Hoffmann Group GARANT 202247 (solid carbide MTC end mill, long reach, uncoated, N/O), hoffmann-group.com/US/en/hus/p/202247-<dc>; GARANT Master Steel SlotMachine 205556 (TiAlN, long neck, P/M/K), hoffmann-group.com/US/en/hus/p/205556-<dc>; dc, lc, D1 and L1 read from each product page", Bool.pick(String, String.eq(t, "bore_bar"), "steel boring bar A..SCLCR 95 degree for CC.. inserts, helical flutes: shank diameter ds, minimum bore dmin, overall length l, head length l1 | source: Hoffmann Group GARANT Master Turn 260030 (A08H, A10K, A12L SCLCR06; A16Q, A20R SCLCR09; A25R SCLCR12), hoffmann-group.com/GR/el/pangakis/p/260030-<ds>%402F<insert>; Hole diameter min. D1 from each product page", Bool.pick(String, String.eq(t, "bar_overhang"), "maximum tool overhang of a steel boring bar as a multiple of the bar diameter BD, for turning, grooving and threading | source: Sandvik Coromant, General turning: tool set-up, sandvik.coromant.com/en-gb/knowledge/general-turning/tool-set-up (steel bars 4 x BD turning, 3 x BD grooving and threading; carbide 6 and 5 and damped 7 to 14 are not held)", Bool.pick(String, String.eq(t, "igroove_insert"), "solid carbide micro grooving insert, internal, square profile: minimum bore dmin, insert width w, maximum radial cutting depth ap, usable length l1 from the bore mouth | source: Hoffmann Group GARANT 270314 4,2/1 (micro grooving insert, internal, right-hand, L1 = 20 mm), hoffmann-group.com/US/en/hus/p/270314-4%2C2@2F1", Bool.pick(String, String.eq(t, "fgroove_tool"), "axial (face) grooving cutting head: smallest and largest groove diameter of the first plunge d1 and d2, insert width w, maximum groove depth tmax; a wider groove takes several plunges | source: Hoffmann Group GARANT 273823 (Schneidentraeger konkav fuer Planeinstich, links), hoffmann-group.com/p/273823-<d1>%402F<d2>, variants 26/41, 38/55, 52/72, 67/100 and 90/130 read from their product pages", Bool.pick(String, String.eq(t, "slitting_saw"), "HSS metal slitting saw, fine teeth (DIN 1837, tooth form A): diameter d, thickness t (the kerf), arbor bore, maximum cutting depth cut (radial reach past the arbor collar); a slot whose walls stand t or more apart and that opens to a setup in its own plane is sawn on a spindle square to its walls, in passes of t | source: Hoffmann Group (Re-Bo) metal circular saw blade fine, uncoated, family 175000 (DIN 1837), hoffmann-group.com/US/en/hus/p/175000-<d>X<t>: Diameter of mounting hole D3 and Maximum cutting depth read from the 40X1, 50X1, 63X1, 63X2,5, 80X1 and 100X1 product pages; only those six are held", Bool.pick(String, String.eq(t, "nema_flange"), "NEMA ICS 16-2001 Table 4, mounting flanges of inch-dimension step motors: frame, bolt circle M of the C flange (tapped holes), pilot diameter N max and its lower deviation, maximum flange P, pilot depth T min and max, and the major diameter of the C flange's tapped thread (UNC 4-40 for frame 17, 8-32 for frame 23), in inches; four holes on M at 45 degrees to the flats | source: engineersedge.com/motors/stepper_motor_size_dimensions_table_14794.htm (NEMA ICS 16 Table 4); pilot depth T from aspina-group.com/en/learning-zone/columns/what-is/034 (NEMA ICS 16-2001 Tables 2 and 4); UNC #4 and #8 major diameters 0.112 and 0.164 in (ASME B1.1)", ""))))))))))))))))))))))

def table_of(+c: String) -> String:
  Bool.pick(String, String.eq(c, "clear_fine"), "clear", Bool.pick(String, String.eq(c, "clear_medium"), "clear", Bool.pick(String, String.eq(c, "clear_coarse"), "clear", Bool.pick(String, String.eq(c, "shcs_dk"), "shcs", Bool.pick(String, String.eq(c, "shcs_k"), "shcs", Bool.pick(String, String.eq(c, "shcs_s"), "shcs", Bool.pick(String, String.eq(c, "shcs_t"), "shcs", Bool.pick(String, String.eq(c, "shcs_b"), "shcs", Bool.pick(String, String.eq(c, "cbore_d"), "cbore", Bool.pick(String, String.eq(c, "cbore_t"), "cbore", Bool.pick(String, String.eq(c, "csk_dk"), "cskh", Bool.pick(String, String.eq(c, "csk_k"), "cskh", Bool.pick(String, String.eq(c, "csk_d"), "csk", Bool.pick(String, String.eq(c, "hex_af"), "hex", ""))))))))))))))

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

def t_slitting_saw() -> List<&2, List<&2, F64>>:
  [[40.0f64, 1.0f64, 10.0f64, 10.25f64],
   [50.0f64, 1.0f64, 13.0f64, 12.75f64],
   [63.0f64, 1.0f64, 16.0f64, 19.25f64],
   [63.0f64, 2.5f64, 16.0f64, 19.25f64],
   [80.0f64, 1.0f64, 22.0f64, 23.0f64],
   [100.0f64, 1.0f64, 22.0f64, 30.25f64]]

def t_nema_flange() -> List<&2, List<&2, F64>>:
  [[17.0f64, 1.725f64, 0.8661f64, F64.neg(0.002f64), 2.36f64, 0.03f64, 0.09f64, 0.112f64],
   [23.0f64, 2.625f64, 1.5f64, F64.neg(0.002f64), 3.21f64, 0.06f64, 0.13f64, 0.164f64]]

def tab(+t: String) -> List<&2, List<&2, F64>>:
  Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "ring_shaft"), t_ring_shaft(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "ring_bore"), t_ring_bore(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "key"), t_key(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "drill"), t_drill(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "endmill"), t_endmill(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "csink"), t_csink(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "tap"), t_tap(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "groove_insert"), t_groove_insert(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "thread_insert"), t_thread_insert(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "endmill_reach"), t_endmill_reach(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "bore_bar"), t_bore_bar(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "bar_overhang"), t_bar_overhang(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "igroove_insert"), t_igroove_insert(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "fgroove_tool"), t_fgroove_tool(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "slitting_saw"), t_slitting_saw(), Bool.pick(List<&2, List<&2, F64>>, String.eq(t, "nema_flange"), t_nema_flange(), []))))))))))))))))

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

def mats() -> List<&2, Fa>:
  [Fa{"AL2618-T61", [2767.9904710203127f64, 2.079e-05f64, 73773.90303690147f64, 0.33f64, 379.21165112425984f64, 289.5798063130712f64]},
   Fa{"AL-A356.0-T6", [2684.9507568897034f64, 2.151e-05f64, 71705.47584895095f64, 0.33f64, 262.0007771403977f64, 193.0532042087141f64]},
   Fa{"IN718-AMS5663", [8220.931698930328f64, 1.278e-05f64, 202705.86441914982f64, 0.29f64, 1241.0563127703049f64, 1034.213593975254f64]},
   Fa{"IN718-AMS5383", [8220.931698930328f64, 1.278e-05f64, 202705.86441914982f64, 0.29f64, 827.3708751802033f64, 723.9495157826778f64]},
   Fa{"HASTELLOY-X", [8220.931698930328f64, 1.368e-05f64, 205463.76733641716f64, 0.32f64, 703.2652439031729f64, 303.36932089940785f64]},
   Fa{"INCONEL-625", [8442.370936611953f64, 1.2851999999999998e-05f64, 205463.76733641716f64, 0.28f64, 820.476117887035f64, 379.21165112425984f64]},
   Fa{"A286-AMS5732", [7944.132651828297f64, 1.6559999999999997e-05f64, 200637.4372311993f64, 0.31f64, 896.3184481118869f64, 586.0543699193107f64]},
   Fa{"17-4PH-H1075", [7833.413032987483f64, 1.1429999999999999e-05f64, 196500.5828552983f64, 0.27f64, 999.7398075094123f64, 861.8446616460451f64]},
   Fa{"AISI304-ANN", [7916.452747118094f64, 1.602e-05f64, 199947.96150188247f64, 0.27f64, 503.31728240129036f64, 179.2636896223774f64]},
   Fa{"TI-6AL-4V-ANN", [4428.7847536325f64, 9.09e-06f64, 116521.3982545453f64, 0.31f64, 861.8446616460451f64, 786.0023314211932f64]},
   Fa{"WASPALOY-AMS5704", [8248.611603640531f64, 1.2149999999999999e-05f64, 210979.57317095186f64, 0.3f64, 1206.5825263044633f64, 827.3708751802033f64]}]

def mat(+g: String) -> Fa:
  fa_go(mats(), g)

def mat_ok(+g: String) -> Bool:
  Bool.not(String.is_empty(fa_m(mat(g))))

def mat_cite(+g: String) -> String:
  Bool.pick(String, String.eq(g, "AL2618-T61"), "2618-T61 aluminium alloy die forging AMS-A-22771, MIL-HDBK-5J Table 3.2.13.0(b) p512; expansion Figure 3.2.13.0 p511", Bool.pick(String, String.eq(g, "AL-A356.0-T6"), "A356.0-T6 aluminium alloy casting, strength class 1 AMS-A-21180, MIL-HDBK-5J Table 3.9.5.0(b) p809; expansion Figure 3.9.4.0 p807", Bool.pick(String, String.eq(g, "IN718-AMS5663"), "Inconel 718 forging, solution treated and aged AMS 5663, MIL-HDBK-5J Table 6.3.5.0(c) p1093; expansion Figure 6.3.5.0 p1091", Bool.pick(String, String.eq(g, "IN718-AMS5383"), "Inconel 718 investment casting AMS 5383, MIL-HDBK-5J Table 6.3.5.0(d) p1094; expansion Figure 6.3.5.0 p1091", Bool.pick(String, String.eq(g, "HASTELLOY-X"), "Hastelloy X sheet, solution treated AMS 5536, MIL-HDBK-5J Table 6.3.1.0(b) p1062; expansion Figure 6.3.1.0 p1063", Bool.pick(String, String.eq(g, "INCONEL-625"), "Inconel 625 sheet, annealed AMS 5599, MIL-HDBK-5J Table 6.3.3.0(b) p1075; expansion Figure 6.3.3.0 p1074", Bool.pick(String, String.eq(g, "A286-AMS5732"), "A-286 bar, solution treated and aged AMS 5732, MIL-HDBK-5J Table 6.2.1.0(b) p1046; expansion Figure 6.2.1.0 p1045", Bool.pick(String, String.eq(g, "17-4PH-H1075"), "17-4PH stainless steel forging, H1075 AMS 5643, MIL-HDBK-5J Table 2.6.9.0(d) p252; expansion Figure 2.6.9.0 (H1075 curve) p255", Bool.pick(String, String.eq(g, "AISI304-ANN"), "AISI 304 stainless steel sheet, annealed (properties of AISI 301 annealed per footnote b) AMS 5513, MIL-HDBK-5J Table 2.7.1.0(b) p277; expansion Figure 2.7.1.0 (annealed) p278", Bool.pick(String, String.eq(g, "TI-6AL-4V-ANN"), "Ti-6Al-4V bar, annealed AMS 4928, MIL-HDBK-5J Table 5.4.1.0(c1) p946; expansion Figure 5.4.1.0 p952", Bool.pick(String, String.eq(g, "WASPALOY-AMS5704"), "Waspaloy forging, solution, stabilization and precipitation heat treated AMS 5704, MIL-HDBK-5J Table 6.3.8.0(b) p1131; expansion Figure 6.3.8.0 p1132", "")))))))))))

def mat_grades() -> String:
  "AL2618-T61 AL-A356.0-T6 IN718-AMS5663 IN718-AMS5383 HASTELLOY-X INCONEL-625 A286-AMS5732 17-4PH-H1075 AISI304-ANN TI-6AL-4V-ANN WASPALOY-AMS5704"
