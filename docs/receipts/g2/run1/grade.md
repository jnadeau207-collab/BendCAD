# G2 grade

Verdict: **PASS** (25/25 checks pass)

Graded from the exported STEP files with OCCT (build123d 0.13) as a reader only; no BendCAD call.

| Check | Result | Numbers |
|---|---|---|
| part.body | PASS | solids=1, step_volume=98055.64300435386, certified=[98055.63303300901, 98055.65293033933], mass_kg=0.2647502361117554, evidence="body.stp" |
| part.front_cover | PASS | solids=1, step_volume=252324.11905548687, certified=[252324.11899171834, 252324.118992223], mass_kg=0.6812751214498146, evidence="front_cover.stp" |
| part.rear_cover | PASS | solids=1, step_volume=99091.37628370157, certified=[99091.37626640192, 99091.37626660011], mass_kg=0.2675467159659943, evidence="rear_cover.stp" |
| part.drive_gear_shaft | PASS | solids=1, step_volume=27411.152607940152, certified=[27411.152607743923, 27411.152607798747], mass_kg=0.21517754797233019, evidence="drive_gear_shaft.stp" |
| part.idler_gear_shaft | PASS | solids=1, step_volume=16126.07229754302, certified=[16126.072297713872, 16126.072297746126], mass_kg=0.1265896675357127, evidence="idler_gear_shaft.stp" |
| part.key | PASS | solids=1, step_volume=346.7398, certified=[346.7397999996693, 346.7398000003308], mass_kg=0.0027219074300000004, evidence="key.stp" |
| part.bushing_DU1615 | PASS | solids=1, step_volume=801.106123771729, certified=[801.1061266653452, 801.1061266654491], mass_kg=0.0060884065406651405, evidence="bushing_DU1615.stp" |
| part.bushing_DU1215 | PASS | solids=1, step_volume=612.6105652372048, certified=[612.6105674499709, 612.6105674500488], mass_kg=0.004655840295802757, evidence="bushing_DU1215.stp" |
| part.lip_seal_16x28x7 | PASS | solids=1, step_volume=1636.4095365626702, certified=[1636.4095365626001, 1636.4095365627393], mass_kg=0.0046310389884723566, evidence="lip_seal_16x28x7.stp" |
| part.circlip_DIN472_28 | PASS | solids=1, step_volume=316.4449599992664, certified=[316.44495975269916, 316.4449597533341], mass_kg=0.0024840929359942416, evidence="circlip_DIN472_28.stp" |
| part.screw_ISO4762_M8x80 | PASS | solids=1, step_volume=4958.389244282185, certified=[4958.389255357723, 4958.389255368928], mass_kg=0.038923355567615156, evidence="screw_ISO4762_M8x80.stp" |
| part.dowel_ISO8734_6x50 | PASS | solids=1, step_volume=1407.38324332577, certified=[1407.3832433256823, 1407.3832433258578], mass_kg=0.010991663130374264, evidence="dowel_ISO8734_6x50.stp" |
| part.o_ring_NBR70_racetrack | PASS | solids=1, step_volume=802.180365274638, certified=[802.1803652734235, 802.1803652758596], mass_kg=0.0010027254565932976, evidence="o_ring_NBR70_racetrack.stp" |
| mass.total | PASS | step_mass_kg=1.764914455262543, certified=[1.7649144285391003, 1.7649144822648473] |
| assembly.instances | PASS | solids=20, instances=20, mismatched=[] |
| interference.full | PASS | pairs_checked=67, pairs_total=190, unexpected=[], thread_overlap_mm3=278.2759940695506, thread_bad=[], press_nominal_contact=[["bush_front_drive", "front_cover"], ["bush_front_idler", "front_cover"], ["bush_rear_drive", "rear_cover"], ["bush_rear_idler", "rear_cover"]], press_bad=[], rule="only the four M8 tapped holes overlap, each by the 6.8 mm tap-drill to 8 mm major annulus over the certified engagement; the four press fits touch at nominal size (interference is the declared ISO 286 fit); every other pair clear or touching", method="occt-boolean common volume, box-pruned", evidence="q/interf_occt.json" |
| envelope | PASS | box_mm=[[-44.0000001, -66.20000010000001, -66.10000009999999], [44.0000001, 66.20000010000001, 68.05000009999999]], size_mm=[88.0000002, 132.40000020000002, 134.15000019999997] |
| flange.pilot | PASS | pilot_diameter_mm=[82.55] |
| flange.holes | PASS | hole_centres=[[0.0, -53.2], [22.05, 0.0], [0.0, 53.2]], span_mm=106.4 |
| ports | PASS | port_axes="y (perpendicular to z gear axes)", max_bore_radius_mm={"neg": 13.0, "pos": 14.5} |
| clearance.tip | PASS | drive_mm=0.029900010196210303, idler_mm=0.029900299519702515, window=[0.02, 0.06], ra_drive=12.652499999979117, ra_idler=12.652499999852902 |
| clearance.side | PASS | drive_mm=0.024999999999991473, idler_mm=0.02499999999999858, window=[0.02, 0.05] |
| mesh | PASS | min_gap_mm=0.046842295217522686, steps=120, pitch_deg=30 |
| displacement | PASS | cm3_per_rev=7.815285456233352, method="flow integral b*(2ra^2-rho1^2-rho2^2)/2 over the contact path of the exported outlines", window=[7.76, 8.24] |
| fits.in_calls | PASS | claimed=17, missing=[], evidence="calls.jsonl" |
