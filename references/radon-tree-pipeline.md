# Fas 2 — Utökad gräsmatta

## Context

Trädet har idag 502 653 bakade splat-punkter. Cirka p25 (≈ 25 %) sitter vid `Y ≤ -0.91` och animeras av en fungerande skimmer-kedja inuti `/project1/GaussianSplatting/TreePoints`. Vi vill ha **bredare gräsmatta runt trädet** — fler vita punkter på samma platta Y som befintligt gräs, glesare utåt (decay), som **ärver shimmret gratis** genom att mergas in **uppströms** om skimmer-kedjan.

Hela skimmer-kedjan och alla `Skim*`-ratter är låsta — ingen ändring där. Nytt gräs ska gå att stänga av utan att röra något befintligt (safety-net, samma princip som SquirrelLandParticles).

---

## Arkitekturbeslut

**Nytt `baseCOMP` `ground_spread` INUTI TreePoints**, vid sidan av huvudkedjan. Output dras in via en `selectPOP` och mergas via en `mergePOP` placerad **mellan `cd_convert` och `extract_y`**. Skälen: nya punkter ärver TreePoints material (`mat_pointcolor` constantMAT) automatiskt genom att joina samma stream, parameterägarskap blir co-located med befintliga `Skim*`-ratter, och hela spreadern är en kollapsbar enhet som kan kapslas/raderas senare som ett block.

**Disable-pattern**: bind `merge_grass.par.bypass` till `1 - parent.TreePoints.par.Groundenable`. När `Groundenable=0` passerar `cd_convert` rakt genom merge → `extract_y` får bit-identisk input → render är byte-identisk med baseline. (Fallback om mergePOP-bypass inte forwardar input 0 utan ger null: ersätt med `switchPOP` efter merge — verifieras i Steg 0.)

---

## Verifierat live state (från Phase 1)

- **Skimmer-kedja**: `treeply_in → splat_xform → pointscale_attr → cd_convert → extract_y (mathcombinePOP) → compute_mask (mathPOP, [-0.91,-0.85]→[1.0,0.0]) → clamp_mask (mathcombinePOP) → grass_noise (noisePOP simplex4d, amp=0.0084, period=0.3) → apply_masked_noise (mathcombinePOP, P+=disp*mask) → OUT`
- **Mask-fönster**: full shimmer vid `Y ≤ -0.91`. Nytt gräs **MÅSTE** ligga vid `Y ≤ -0.91` (häcka i clampMax på `Groundy`).
- **Material aktivt**: `mat_pointcolor` (constantMAT, alpha=0.03, depthwriting=False, blending=True, pointscaleattrib='PointScale', applypointcolor=True). **Inte** pointspriteMAT som mitt minne sade.
- **PointScale aktuellt**: `0.02` (uniform via `pointscale_attr`).
- **Y-distribution alla 502k punkter**: median=-0.367, p25=-0.921, p10=-0.934 → grovt grass-band sitter runt Y ≈ -0.92 men **grass-only median uppmätt först i Steg 0**.
- **Baseline fps**: 61.

---

## Steg 0 — OBLIGATORISK checkpoint (rapportera siffror, vänta på OK)

1. **SAVE FIRST** — `project.save()` **innan något annat**, verifiera `.toe` mtime advanced ≥ nuvarande systemtid. Vi har flera trådar i samma TD-instans och jag har inte sett en bekräftad save sedan snap-fixen + den parkerade partikel-pipelinen. Bekräfta uttryckligen att de finns på disk innan TreePoints rörs. Om mtime inte advanced → STOP, rapportera.
2. Envoy responsive: `execute_python` → `result = absTime.frame` (≥1, inga timeouts).
3. `query_network('/project1/GaussianSplatting/TreePoints')` → bekräfta att alla 9 ops + connections matchar Phase 1-fyndet exakt. Avbryt om mismatch.
4. `get_parameter` på `pointscale_attr` → bekräfta `PointScale = 0.02` (literal som nytt gräs ska sätta).
5. `get_parameter` på TreePoints `Material` → bekräfta `mat_pointcolor`.
6. `get_parameter` på TreePoints custom page → bekräfta `Skimygrass=-0.91`, `Skimycrown=-0.85`.
7. `get_network_layout` på TreePoints interior → spara koordinater + nodeWidth för varje op (krävs för placering).
8. **Grass-only Y-mätning**: `execute_python` mot `cd_convert` (post-transform, pre-mask) med `numpyArray('P')`, filtrera `y < -0.85`, returnera `count, min, p10, p25, median, p75, p90, max`.
9. **Grass-only XZ-radie**: samma filter, returnera `sqrt(x²+z²)` → `p50, p90, p99, max` (`p99` blir defaultvärde för `Groundinnercut`).
10. Bekräfta TreePoints `parentshortcut='TreePoints'` (Common page). Om tomt → flagga som extra steg.
11. **POP-ONLY RANDOM-VERIFIERING (kritisk — INGEN glslPOP-fallback utan bevis)**: Innan bygget startar, testa BÅDA dessa POP-only-vägar i en throwaway-test-COMP (sibling till TreePoints, deleteras efter):
    - **Try A**: `attributecreatePOP` med per-punkt expression. Testa t.ex. `(me.curPoint.index * 2654435761 % 1000000) / 1e6` → bekräfta att resultatet är (a) unikt per punkt (b) stabilt över frames (c) jämnt fördelat ∈ [0,1] genom att sampla 1000 punkter.
    - **Try B**: `noisePOP` med simplex på P som input → output skalär. Testa samma kriterier.
    - **Rapportera resultat: vilken funkar, eller om båda misslyckas.** Om båda misslyckas → **STOP**, rapportera explicit till användaren, bygg INTE glslPOP-vägen reflexmässigt. Vänta på instruktion.
12. **Capture baseline** (render TOP via `capture_top`), spara sha256.
13. **Räkna defaults**:
    - `Groundy = round(median(grass_y), 2)` (förväntat ≈ -0.92, clampMax = -0.91)
    - `Groundinnercut = round(p99(grass_radius), 2)` (förväntat ≈ 0.6–1.0)
    - `Groundradius = round(Groundinnercut + 1.5, 1)` (utåt-räckvidd, finjusteras live)
14. **STOP — rapportera siffror + POP-random-resultat + capture-hash till användaren. Vänta på explicit godkännande innan bygge.**

---

## Custom parameters (på TreePoints, ny page `Ground`)

Per `.claude/rules/parameters.md`: `appendCustomPage` → `appendXxx()` ger ParGroup, indexera `[0]` för Par. Sätt `default`, range, `help`, `startSection` på första.

| # | Namn | Style | Default | Range | Help |
|---|---|---|---|---|---|
| 1 | `Groundenable` | Toggle | `1` | – | "Master switch for extra ground grass. 0 = render byte-identical to baseline. 1 = inject scattered ground points upstream of the skimmer chain so they inherit shimmer." (`startSection=True`) |
| 2 | `Groundradius` | Float | `2.5` | min=0.1, max=10, clampMin=True, clampMax=False, normMin=0.5, normMax=5 | "Outer radius (m) of the scatter disc around the tree center. Overshoot the baked-grass disc so new grass fills outward." |
| 3 | `Grounddensity` | Float | `200` | min=1, max=10000, clampMin=True, normMin=10, normMax=2000 | "Target points per m² before inner-cut and decay culling. Total spawned ≈ π·Groundradius²·Grounddensity." |
| 4 | `Groundinnercut` | Float | `1.0` | min=0, max=10, clampMin=True, normMin=0, normMax=3 | "Inner radius (m). No new points below this. Should match the baked-grass disc outer edge (p95 = 0.98) — seamless overlap." |
| 5 | `Grounddecay` | Float | `0.5` | min=0, max=1, clampMin=True, clampMax=True, normMin=0, normMax=1 | "Radial density falloff. 0 = uniform full disc. 0.5 = ~22% density at edge. 1.0 = ~5% at edge. Formula: keep = exp(-decay·3·r/R)." |
| 6 | `Groundy` | Float | `-0.92` | min=-2.0, **max=-0.91** (clampMax=True — låst inom mask-bandet), normMin=-1.0, normMax=-0.91 | "Y (m) for the scatter plane. Hard-clamped to ≤ Skimygrass (-0.91). Default = median grass-Y from baked PLY (-0.9249)." |
| 7 | `Groundpointscale` | Float | `0.005` | min=0.0001, max=0.1, clampMin=True, normMin=0.001, normMax=0.02 | "PointScale value for new grass. Baked grass has per-point PointScale from PLY (median=0.0023, p90=0.007). 0.005 is a visible compromise." |
| 8 | `Groundalpha` | Float | `11` | min=0, max=255, clampMin=True, clampMax=True, normMin=0, normMax=50 | "Color.a (alpha) for new grass on 0-255 byte scale (matches baked Color attr). Baked grass median=11, p90=28. Lower = more transparent." |

---

## POP-kedja inuti `ground_spread`

Built-in POPs only (Mac Metal-safe, **ingen glslPOP** — Fas B är blockerad på glslPOP P-write och vi auto-fallbackar INTE hit. POP-random valideras explicit i §0.11). All läsning från ratter via `parent.TreePoints.par.Xxx` (förutsatt parent shortcut satt i §0.10).

**Scatter-strategi**: organisk sprinkle på fylld disc-yta (Squirrel-mönstret) — inga grid-artefakter.

| # | Namn | Type | Input | Nyckelparametrar | Output |
|---|---|---|---|---|---|
| 1 | `disc_sop` | `circleSOP` | – | `type='polygon'`, `arc='full'`, fylld disc (genererad som faces, inte bara perimeter — TO VERIFY param-namn för fyllning, fallback `gridSOP`+`convertSOP` till disc via radie-cut), `radiusx=radiusy=parent.TreePoints.par.Groundradius`, `orientation` så ytan ligger platt i XZ-planet, divisions hög (64+) | (yta) |
| 2 | `sprinkle` | `sprinklePOP` (eller `scatterSOP→sopToPOP` om sprinklePOP inte stödjs) | `disc_sop` | `count = ceil(π·Groundradius²·Grounddensity)` via expression, `seed = 1` stabil, `distribution='area'` så täthet blir uniform över ytan | P (organiska, ingen grid-struktur) |
| 3 | `flatten_y` | `mathcombinePOP` | `sprinkle` | sätter `P.y = parent.TreePoints.par.Groundy` (set-op på Y-komponent) — defensivt även om disc redan är platt | P (Y flat) |
| 4 | `radius_attr` | `mathcombinePOP` | `flatten_y` | skriver attribut `radius = length(P.xz)` | + `radius` |
| 5 | `rand_noise` | `noisePOP` (Try B-verifierad i §0.11) | `radius_attr` | `noise=True, combineop='none', noiseoutputattrscope='rndvec', period=0.05, amp0=1.0, seed=42, t4d=0` → vec3 simplex noise per punkt | + `rndvec` |
| 6 | `keep_attr` | `mathcombinePOP` | `rand_noise` | beräknar `keep = step((rndvec.x + 1) * 0.5, exp(-Grounddecay·3·radius/Groundradius)) * step(Groundinnercut, radius) * step(radius, Groundradius)` — alla 3 villkor i ett uttryck | + `keep` |
| 7 | `cull` | `deletePOP` | `keep_attr` | `delcondition: keep < 0.5` (TO VERIFY: deletePOP predikat-syntax; fallback: `attributePOP` som flaggar grupp + `deletePOP` på grupp) | (subset) |
| 8 | `set_color` | `attributePOP` | `cull` | attr-sequence count=1, attrclass='point', `Color (vec4) = (255, 255, 255, Groundalpha)` — matchar bakade gräsets 0-255-skala | + `Color` |
| 9 | `set_ps` | `attributePOP` | `set_color` | attr-sequence count=1, `PointScale (float) = Groundpointscale` (default 0.005) | + `PointScale` |
| 10 | `OUT` | `nullPOP` | `set_ps` | sätt som baseCOMP `outputs[0]` (TO VERIFY: hur baseCOMP exponerar POP-output — alternativ: selectPOP utanför refererar `./ground_spread/OUT` direkt) | passthrough |

**Varför sprinkle, inte grid+jitter**: grid+svag jitter ger synliga linjer; grid+stark jitter ger oregelbunden täthet vid cell-gränser. Sprinkle på fylld disc ger organisk Poisson-aktig fördelning från start utan artefakter och utan en extra op.

**Decay-formel**: `keep_probability = exp(-decay·3·r/R)`, valt över linjär för smidig gradient utan kink — en enda ratt täcker full sweep.

**Attribut-namn (verifierat i §0.4 mot cd_convert.pointAttributes)**: Bakat gräs har `(P: vec3, Color: vec4, PointScale: float)`. **Det är `Color`, INTE `Cd`** — och Color är **0-255 byte-skala** (R=G=B=255 för grass), inte 0-1 float. Nya gräspunkter måste matcha eller render-pipelinen bryts.

**Merge-säkerhet (verifierat efter §0.5)**: `grass_noise.noiselookupattr='P'` — noise samplas på position, inte pointID. Att lägga till nya punkter via merge påverkar inte befintliga punkters `disp`-värde. Input-ordning input[0]=bakat / input[1]=nytt bevarar pointID-numrering på bakade, men det spelar mindre roll när noise är P-baserad.

---

## Insättning i huvudkedjan

1. `disconnect_op` `cd_convert → extract_y`.
2. Flytta `extract_y, compute_mask, clamp_mask, grass_noise, apply_masked_noise, OUT` **höger** med `merge_grass.nodeWidth + 200` (läses efter create_op via `get_op`).
3. `create_op` `selectPOP` `select_ground_spread`, `select` param = `./ground_spread/OUT`. Position: 400 under merge_grass, samma X.
4. `create_op` `mergePOP` `merge_grass`. Bind `par.bypass = 1 - parent.TreePoints.par.Groundenable`.
5. `connect_ops`: `cd_convert → merge_grass.input[0]`, `select_ground_spread → merge_grass.input[1]`, `merge_grass → extract_y`.
6. **Input-ordning kritisk**: input[0] = bakade punkter först (downstream-noise indexerar potentiellt på pointID).
7. `get_op_errors` recurse=True på TreePoints.
8. Ny annotation `Ground spread (Fas 2)` enclosing `ground_spread, select_ground_spread, merge_grass` per `.claude/rules/network-layout.md` (200 padding, nodeY = bottom-left).

---

## Verifiering (capture-driven — INTE errors=0)

1. **Disable-equals-baseline (kritisk safety check)**: `Groundenable=0`, capture render TOP, sha256 → MÅSTE matcha §0.11. Om inte → STOP, rotorsaka (förmodligen merge-bypass-semantik fel → fallback switchPOP).
2. **Full disc** (`Groundenable=1, Grounddecay=0`): jämn vit gräsmatta från `Groundinnercut` till `Groundradius`, inga synliga skarvar mot bakat gräs.
3. **Soft falloff** (`Grounddecay=0.5`): synlig glesning utåt, ingen hård kant.
4. **Hard falloff** (`Grounddecay=1.0`): tunn yttre rand (~5% densitet), full center.
5. **Inner-cut sweep** (`±0.2` från default): ingen overlap-band och ingen gap mot bakat.
6. **Shimmer-sync** (capture 2 frames ~10 frames isär, `enable=1`): både bakat och nytt gräs flimrar. Om nytt står stilla → check `Groundy ≤ -0.91`, check merge-position FÖRE extract_y, check att P/Cd/PointScale-attributnamn matchar.
7. **Crown unchanged**: capture kron-region, bekräfta orörlig (mask=0 där).
8. **fps**: baseline 61. Mät efter. **Flagga om Δ ≥ 10 fps** → minska `Grounddensity` default till 100.
9. `project.save()` efter alla verifieringar OK. Rapportera.

---

## Skill-load order

Före första MCP-anrop: `/mcp-tools-reference`. Före `execute_python` / `set_dat_content`: `/td-api-reference`. Före första `create_op`: `/create-operator`. Före annotation-ops: `/manage-annotations`. Vid fel: `/debug-operator`. (Skipping `/externalize-operator` — TreePoints är inte TDN-externaliserad, lever i .toe.)

---

## Out of scope (explicit)

- Skimmer-kedjans parametrar (Skim*-ratter, mathcombinePOP/mathPOP/noisePOP configs).
- Mask Y-thresholds (Skimygrass/Skimycrown).
- TreePoints material (mat_pointcolor).
- `treeply_in`, `splat_xform`, `pointscale_attr`, `cd_convert`.
- SquirrelLandParticles (Fas B, pausad).
- Camera, hand control, presence gate, info panels.

---

## Kritiska filer

- `/Users/niklaz.hallberg/Projects/touchdesigner-mcp-projects/RADON_TREE/.claude/rules/network-layout.md`
- `/Users/niklaz.hallberg/Projects/touchdesigner-mcp-projects/RADON_TREE/.claude/rules/parameters.md`
- `/Users/niklaz.hallberg/Projects/touchdesigner-mcp-projects/RADON_TREE/.claude/rules/td-python.md`
- `/Users/niklaz.hallberg/Projects/touchdesigner-mcp-projects/RADON_TREE/.claude/rules/mcp-safety.md`
- `/Users/niklaz.hallberg/Projects/touchdesigner-mcp-projects/RADON_TREE/CLAUDE.md`

Live target: `/project1/GaussianSplatting/TreePoints` i `hand_control_radon_tree.toe`.

---

## Risker — kort

- **Groundy utanför mask-band** → ingen shimmer. *Mitigerat med `Groundy.clampMax = -0.91`.*
- **Attribut-mismatch vid merge** (nytt gräs saknar attribut bakade punkter har — t.ex. splat-rotation/scale). ConstantMAT konsumerar inte dessa, men visuell kontroll i §V.6. Om nytt gräs ser fel ut: lägg `attributecreatePOP` som syntetiserar default-värden.
- **deletePOP predikat-syntax inte stödd** → fallback `attributePOP` som skriver grupp + `deletePOP` filtrerar på grupp. Verifieras i §Steg 0 / build step.
- **gridSOP orientation enum-värde** → verifieras vid första create_op; fallback `transformSOP` rotera 90°.
- **mergePOP `bypass` semantik** → verifieras i §V.1 (disable-baseline). Fallback switchPOP.
- **POP-only random** → om varken `attributecreatePOP`-expression eller `noisePOP` ger ren per-punkt-skalär i §0.11: **STOP, rapportera, vänta på instruktion**. INGEN reflexmässig glslPOP-fallback — det är exakt vägen som blockerat Fas B (P-write i glslPOP).
- **Performance regression** → start `Grounddensity=200` → ~2 500 nya punkter vid radius=2 → trivialt mot 502k. Om fps faller, minska default.

---

## Slutläge

Efter §V.9: ny gräsmatta runt trädet, glesare utåt, shimrar i fas med befintligt. Disable-toggle ger byte-identisk baseline. Fps inom 10 från 61. Pausa, visa capture-serie, vänta på godkännande för nästa fas.

---

# Fas 2b — Naturligare struktur (mjuka kullar + XZ-jitter)

## Context

Fas 2-grundbygget är **klart och sparat** i `hand_control_radon_tree.95.toe`. Nuvarande tunade settings: Groundradius=2.5, Grounddensity=50000, Grounddecay=0.2, Groundinnercut=1.0, Groundy=-0.92, Groundpointscale=0.005, Groundalpha=11 → 642k extra partiklar runt trädet, 60 fps stabil.

Användaren upplever mattan som **"för perfekt"** — sprinklePOP-fördelningen är Poisson-aktig men ser ändå för symmetrisk ut, och alla punkter ligger på EXAKT samma Y (-0.92) vilket ger en helt platt yta. Vill ha **områdesvis höjdvariation** (breda regioner som ligger högre/lägre + lokala små ojämnheter ovanpå) + lite **XZ-jitter** för att bryta mönstret. På sikt: interaktiv trädgård med robotgräsklippare — terrängen ska kunna styras av höjdkort i framtiden, så strukturera redan nu så heightmap kan kopplas in utan ombyggnad.

## Lösning (oktav-baserad terräng + heightmap-redo)

Lägg till FEM ops i `ground_spread`-kedjan, mellan `flatten_y` och `radius_attr`:

1. `terrain_coarse` (noisePOP) — låg-frekvent simplex på P → output `terrain_coarse` (vec3). Lång våglängd → BREDA regionala höjdskillnader ("en del högre, en del lägre").
2. `terrain_fine` (noisePOP) — hög-frekvent simplex på P → output `terrain_fine` (vec3). Kort våglängd → små lokala knölar OVANPÅ regionerna.
3. `terrain_combine` (mathcombinePOP) — viktad summa: `terrain = terrain_coarse * Groundmacroamt + terrain_fine * Groundmicroamt`. **Detta är den ENDA punkten som producerar `terrain`** → framtida heightmap-sampling kopplas in här som tredje term utan att röra resten av kedjan.
4. `terrain_apply` (mathcombinePOP) — `P = P + terrain * (Groundjitter, Groundkullar, Groundjitter)`. Groundkullar är master-Y-amplitud (skalar HELA terrain-Y-bidraget). Groundmacroamt/microamt styr RELATIV blandning grov-vs-fin.
5. `y_clamp` (mathcombinePOP) — `P = min(P, (1e6, -0.915, 1e6))` — **HÅRD CEILING** på P.y, matematiskt omöjligt att överstiga -0.915 oavsett oktav-amplitud eller ratt-värden.

Resultat: två noise-lager (coarse + fine) summerade och viktade ger landskap-känsla i stället för uniform böljning. Kullar trycks nedåt från taket -0.915 → konsistent shimmer. Heightmap-redo via `terrain_combine` som central summeringspunkt.

**Varför hård clamp, inte default-baserad headroom**: Default-headroom funkar bara medan användaren inte vrider ratterna. Med två oktaver + flera amplitud-rattar finns många vägar att råka skjuta över masken. En `min`-clamp gör det matematiskt omöjligt oavsett rattläge.

**Plats för kedjan (kräver shift höger på radius_attr..OUT med +1000):**
```
disc → sprinkle → flatten_y → terrain_coarse → terrain_fine → terrain_combine → terrain_apply → y_clamp → radius_attr → rand_noise → keep_attr → cull → set_color → set_ps → OUT
```

## Nya rattar (5 st, läggs till på Ground-page efter Groundalpha)

| # | Namn | Style | Default | Range | Help |
|---|---|---|---|---|---|
| 9 | `Groundjitter` | Float | `0.02` | min=0, max=0.5, clampMin=True, normMin=0, normMax=0.1 | "XZ-jitter amplitude (m). Breaks up sprinkle's residual regularity. 0 = no jitter, 0.05 = subtle, 0.1 = chaotic. Doesn't affect Y." (`startSection=True`) |
| 10 | `Groundkullar` | Float | `0.05` | min=0, max=0.3, clampMin=True, clampMax=True, normMin=0, normMax=0.15 | "MASTER Y-amplitude for hills (m). Scales the combined terrain. Toppen av kullarna trunkeras alltid vid Y=-0.915 (clamp), så stora värden ger flatare topp. 0 = helt platt." |
| 11 | `Groundmacroperiod` | Float | `6.0` | min=1.0, max=20, clampMin=True, normMin=2, normMax=15 | "Wavelength of LARGE terrain forms (m). High = a few broad hills covering big regions. Low = more frequent rises. Controls the 'different areas have different heights' feel." |
| 12 | `Groundmacroamt` | Float | `1.0` | min=0, max=2, clampMin=True, clampMax=True, normMin=0, normMax=2 | "Weight of LARGE-scale terrain. Higher = more pronounced regional height differences. 0 = no large forms (only fine bumps)." |
| 13 | `Groundmicroperiod` | Float | `1.5` | min=0.3, max=5, clampMin=True, normMin=0.5, normMax=3 | "Wavelength of FINE surface bumps (m). Low = many small bumps. High = sparser bumps. Use as detail-layer on top of macro forms." |
| 14 | `Groundmicroamt` | Float | `0.4` | min=0, max=2, clampMin=True, clampMax=True, normMin=0, normMax=1 | "Weight of fine bumps on top of large forms. Keep lower than Groundmacroamt for natural look (otherwise micro dominates and macro disappears)." |

(That's 6 new ratter — tre par: Groundjitter standalone, plus Groundkullar (master), plus 4 oktav-ratter macro/micro × period/amt.)

**Inga ändringar på Groundy default** — clamp-op gör headroom obehövd.

## Op-konfiguration

### terrain_coarse (noisePOP) — stora regionala former

| Param | Värde |
|---|---|
| `attrclass` | `point` |
| `noise` | `True` |
| `combineop` | `none` |
| `noiselookupattr` | `P` |
| `noiseoutputattrscope` | `terrain_coarse` |
| `period` | expression: `parent.TreePoints.par.Groundmacroperiod` |
| `amp0` | `1.0` (vikt sker i terrain_combine) |
| `seed` | `7` |
| `t4d` | `0` (statisk) |

### terrain_fine (noisePOP) — lokala små knölar

| Param | Värde |
|---|---|
| `attrclass` | `point` |
| `noise` | `True` |
| `combineop` | `none` |
| `noiselookupattr` | `P` |
| `noiseoutputattrscope` | `terrain_fine` |
| `period` | expression: `parent.TreePoints.par.Groundmicroperiod` |
| `amp0` | `1.0` (vikt sker i terrain_combine) |
| `seed` | `19` (skiljt från coarse seed=7, rand_noise seed=42) |
| `t4d` | `0` (statisk) |

### terrain_combine (mathcombinePOP) — viktad summering, heightmap-redo

`vec` sequence count = 2, `comb` sequence count = 2

```
# FUTURE HEIGHTMAP HOOK: To add painted heightmap control later, sample a TOP
# into a third attribute (e.g. 'terrain_map') and add a third comb block:
#   comb2: oper=aaddbmultc, scopea=terrain (current), scopeb=terrain_map, scopec=vec_heightmap_weight, result=terrain
# No other changes needed — terrain_apply downstream consumes 'terrain' regardless of how many sources combined here.
```

| Param | Värde |
|---|---|
| `attrclass` | `point` |
| `vec0name` | `macro_w` |
| `vec0type` | `float` |
| `vec0value0` | expression: `parent.TreePoints.par.Groundmacroamt` |
| `vec1name` | `micro_w` |
| `vec1type` | `float` |
| `vec1value0` | expression: `parent.TreePoints.par.Groundmicroamt` |
| `comb0oper` | `mult` (weighted_coarse = terrain_coarse * macro_w) |
| `comb0scopea` | `terrain_coarse` |
| `comb0scopeb` | `macro_w` |
| `comb0result` | `weighted_coarse` |
| `comb1oper` | `aaddbmultc` (terrain = weighted_coarse + terrain_fine * micro_w) |
| `comb1scopea` | `weighted_coarse` |
| `comb1scopeb` | `terrain_fine` |
| `comb1scopec` | `micro_w` |
| `comb1result` | `terrain` |

Sätt en kommentar i op.comment som påminner om heightmap-hook.

### terrain_apply (mathcombinePOP) — applicera viktad terrain på P

`vec` sequence count = 1, `comb` sequence count = 1

| Param | Värde |
|---|---|
| `attrclass` | `point` |
| `vec0name` | `terrain_mask` |
| `vec0type` | `float3` |
| `vec0value0` | expression: `parent.TreePoints.par.Groundjitter` |
| `vec0value1` | expression: `parent.TreePoints.par.Groundkullar` |
| `vec0value2` | expression: `parent.TreePoints.par.Groundjitter` |
| `comb0oper` | `aaddbmultc` (P + terrain*mask) |
| `comb0scopea` | `P` |
| `comb0scopeb` | `terrain` |
| `comb0scopec` | `terrain_mask` |
| `comb0result` | `P` |

### y_clamp (mathcombinePOP) — hård ceiling på P.y

`vec` sequence count = 1, `comb` sequence count = 1

| Param | Värde |
|---|---|
| `attrclass` | `point` |
| `vec0name` | `y_ceiling` |
| `vec0type` | `float3` |
| `vec0value0` | `1000000.0` (effektivt ∞ — påverkar inte X) |
| `vec0value1` | `-0.915` (säker marginal under Skimygrass -0.91; låst konstant) |
| `vec0value2` | `1000000.0` (effektivt ∞ — påverkar inte Z) |
| `comb0oper` | `min` |
| `comb0scopea` | `P` |
| `comb0scopeb` | `y_ceiling` |
| `comb0result` | `P` |

Resultat: `P.x = min(P.x, 1e6) = P.x`, `P.y = min(P.y, -0.915)`, `P.z = min(P.z, 1e6) = P.z`. Säkerhetsmarginal 0.005 till mask-edge -0.91 → topp-punkter har shimmer ≈ 0.92.

## Insättning i ground_spread

1. `flatten_y` blir kvar på (400, 0). Ingen ändring.
2. `radius_attr` shiftas från X=600 → X=1600 (+1000). Alla downstream följer:
   - radius_attr: 1600
   - rand_noise: 1800
   - keep_attr: 2000
   - cull: 2200
   - set_color: 2400
   - set_ps: 2600
   - OUT: 2800
3. Skapa `terrain_coarse` på (600, 0).
4. Skapa `terrain_fine` på (800, 0).
5. Skapa `terrain_combine` på (1000, 0).
6. Skapa `terrain_apply` på (1200, 0).
7. Skapa `y_clamp` på (1400, 0).
8. Disconnect `flatten_y → radius_attr`.
9. Wire: `flatten_y → terrain_coarse → terrain_fine → terrain_combine → terrain_apply → y_clamp → radius_attr`.
   - Sekvensiell kedja: varje noise-op får föregående POP som input (för att passa attribut framåt). terrain_coarse skapar attribut, terrain_fine LÄSER det och ADDS sin egen. terrain_combine läser båda.
10. Konfigurera per tabellerna ovan.
11. Force cook ground_spread/OUT, verifiera errors=0.

## Verifiering (capture-driven)

**Säkerhetsnät FÖRST**: `project.save()` innan bygge (96.toe).

1. **Baseline-check (Groundjitter=0, Groundkullar=0)** — KÖRS FÖRST: Capture. Ska vara visuellt identisk med nuvarande state (642k partiklar, platt yta). Om inte → terrain-ops bryter chain även när maskat till 0. STOP, rotorsaka. Säkerhetsnätet.
2. **Y-clamp-garanti (stress-test)**: `execute_python` på `set_ps` — sample P.y. Vid defaults: bekräfta `max(P.y) ≤ -0.915` EXAKT. Sedan STRESS-TEST: vrid Groundkullar=0.3 (max), Groundmacroamt=2 (max), Groundmicroamt=2 (max), Groundy=-0.91 (max). Sample igen. `max(P.y)` MÅSTE fortfarande vara ≤ -0.915. Om inte → clamp brister (förmodligen `min` ej komponent-vis mot vec3). STOP, byt till 3 separata min-combs eller `clamp`-op. Återställ defaults efter testet.
3. **Macro-only (Groundmicroamt=0, Groundmacroamt=1, Groundkullar=0.08)**: Capture. Ska visa BREDA mjuka nivåskillnader mellan områden — inte uniform böljning. Bekräfta visuell "regional landscape"-känsla.
4. **Micro-only (Groundmacroamt=0, Groundmicroamt=1, Groundkullar=0.08)**: Capture. Ska visa många små lokala knölar, jämnt fördelade. Bekräfta finkornig textur.
5. **Båda (defaults: macro=1, micro=0.4, kullar=0.05)**: Capture. Ska visa breda regioner MED småojämnheter ovanpå — organiskt "landskap, inte böljande matta".
6. **Jitter bryter mönster (Groundjitter=0.05)**: Capture. Mer organisk distribution.
7. **Disable-bypass intakt**: Groundenable=0 → capture ska INTE visa terräng-ändringar (bypass passar igenom cd_convert oförändrat).
8. **Shimmer fortsatt synkat**: capture 2 frames ~10 frames isär med defaults. Både gamla och nya gräset shimrar. Mosaik OMÖJLIG pga clamp.
9. **fps regression**: 5 nya ops i kedjan, mått förväntat. Flagga om Δ ≥ 5 fps.
10. `project.save()` efter alla verifieringar OK.

## Risker — Fas 2b oktav

- **Kullar ovanför mask**: ELIMINERAT av y_clamp. Verify §2 är bevistest.
- **`min`-operator inte komponent-vis** mot float3-mot-float3: Verify §2 fångar det automatiskt — om max(P.y) > -0.915 vid stress, byt till 3 combs (en per komponent) eller använd `clamp` med ceiling-vektor.
- **noisePOP läser föregående POP:s attribut**: terrain_fine får terrain_coarse som input → måste passera 'terrain_coarse' attribut vidare. mathcombinePOP-utgångar förlorar inte attribut, så det borde funka — men verifiera att terrain_combine ser BÅDA terrain_coarse + terrain_fine i input.
- **Period för låg** (<0.3): blir högfrekvent brus istället för mjuka kullar/knölar. Mitigerat via help-text + normMin på rattarna.
- **XZ-jitter trycker punkter utanför disc-radius**: hanteras av `cull` (deletePOP). Inga ops läcker.
- **Heightmap-hook (framtid)**: terrain_combine designad så att tredje comb-block kan läggas till utan röra resten. Kommentar in på op:en.
- **Statisk terräng (t4d=0 på båda noise)**: animerad terräng är separat utbyggnad.

## Out of scope (Fas 2b oktav)

- Animerad terräng (t4d på terrain_*-noise)
- Heightmap-sampling (inkopplas senare via terrain_combine extra comb-block)
- Per-ratt clamp av Groundkullar mot Skimygrass dynamiskt
- Färgvariation (alla punkter behåller `Color = (255,255,255,Groundalpha)`)
- Extra spreader för grus-ringen utåt

## Build order (sammanfattad)

1. Skill-load: `/td-api-reference` (redan laddat), `/create-operator`.
2. **project.save() FIRST** — Fas 2-state (95.toe → blir 96.toe) säker innan ändring.
3. Lägg till 6 nya rattar via befintliga `Ground` page (Groundjitter, Groundkullar, Groundmacroperiod, Groundmacroamt, Groundmicroperiod, Groundmicroamt).
4. Shift radius_attr..OUT positions (+1000 X).
5. Skapa 5 nya ops: terrain_coarse, terrain_fine, terrain_combine, terrain_apply, y_clamp.
6. Disconnect `flatten_y → radius_attr` + rewire ny 5-op-sekvens.
7. Konfigurera per tabellerna (notera op.comment på terrain_combine om heightmap-hook).
8. Force cook, errors=0 check.
9. **Verify §1 FÖRST** (baseline-check med jitter=0, kullar=0) — säkerhetsnätet.
10. **Verify §2 STRESS-TEST** (y_clamp håller vid max alla terräng-rattar). Detta är BEVISET före vidare verifiering.
11. Verifierings-sweep §3-§9 (macro-only, micro-only, both, jitter, bypass, shimmer, fps).
12. project.save() igen, rapportera siffror.

---

# Fas 3 — Miljö-swap (återanvänd pipeline med ny Gaussian splat-PLY)

## Context

Användaren skapar ny film: filmar ny trädgård med iPhone → Gaussian splatting 3D-fil → konverterar till PLY (samma format som `Assets/RADON_Tree_baked.ply`). Mål: återanvänd HELA detta projekt (alla interaktiva features, sliders, shimmer, terräng-modulering, hand-control) med BARA miljön utbytt.

**Bevara**: handcam, sliders (Rotation/Zoom/Camera Height), Resetzoom/Resetlook, Skim-shimmer på gräs, Spots (Spot1/2/3 för höjdmodulering), terräng-noise (macro/micro kullar), tree_radius_cull, tree_grass_thin.

**Ersätt**: tree-PLY-källan (`treeply_in.par.file`) + Skim-Y-thresholds (anpassad till nya miljöns gräs-Y).

**Ta bort**: den syntetiska `ground_spread`-cirkeln — naturlig miljö har redan eget bakat gräs, behöver inte påhittad disc-matta. Behåll dock Spots-funktionalitet men flytta den till tree-grenen så den modulerar de bakade gräspunkterna direkt.

## Kritiska filer

- `Assets/bake_splat_points.py` — PLY-baker (befintligt, återanvänds)
- `Assets/RADON_Tree_baked.ply` → ersätts av `Assets/NEW_ENV_baked.ply`
- `/project1/GaussianSplatting/TreePoints/treeply_in` — PLY-loader, ändra `par.file`
- `/project1/GaussianSplatting/TreePoints` — Ground-page rattar (Skim*, Ground*, Spot*, Tree*)
- `/project1/GaussianSplatting/TreePoints/ground_spread` — sub-COMP som **tas bort eller bypassas**

## Fas 3A — SWAP (lågrisk, ~30-60 min)

### Steg 0 — produktion utanför TD
1. Filma trädgård (iPhone, Polycam/Luma/Reality Capture).
2. Export → .ply Gaussian splat-format.
3. Kör `python Assets/bake_splat_points.py <new_input.ply>` → genererar `Assets/NEW_ENV_baked.ply` (matchar `RADON_Tree_baked.ply`-formatet: P + Color RGBA byte-skala + PointScale).

### Steg 1 — säkerhetspunkt
- `project.save()` (skapa baseline-toe innan swap, t.ex. `.114_BEFORE_ENV_SWAP.toe`).

### Steg 2 — byt PLY-källa
- `treeply_in.par.file = 'Assets/NEW_ENV_baked.ply'`
- Pulse `treeply_in.par.reloadpulse`
- Verify: `treeply_in.numPoints()` matchar förväntad PLY-storlek.

### Steg 2.5 — SKALA + ORIENTERING (BLOCKERANDE, inte risk-fotnot)
**Detta MÅSTE göras innan resten — allt nedströms (Y-trösklar, Spot-radier, terräng-perioder, Groundradius, kamera-zoom) förutsätter rätt absolut skala.**

- Sample bounding box: `cd_convert.points('P')` → numpy → min/max per axel.
- Förvänta scenstorlek i meter: t.ex. en 5×5 m trädgård. Om bbox visar 50×50 m → scen är 10× för stor.
- Justera `splat_xform`:
  - `scale` — normalisera till "rätt-skala-i-meter".
  - `rx/ry/rz` — verifiera upp-axel (iPhone/Polycam ger ofta Z-up, TD vill Y-up → rx=90 eller -90).
  - `ty` — flytta ner så marknivå hamnar runt Y=-0.9 (matchar tidigare Skimygrass-konvention).
- Capture top-down + side view för visuell verifiering: ser scen ut som från ovan? Träd vertikalt?
- Re-sample bbox efter justering, bekräfta scenstorlek matchar förväntan.

**Stoppvillkor**: om bbox är fel skala/orientering efter splat_xform-tweaks → STOP, fixa bake-skriptet eller PLY-input. Resten av planen är meningslös utan rätt skala.

### Steg 3 — sampla nya miljöns gräs-Y (efter skala-normalisering)
- `execute_python` mot `cd_convert.points('P')` → numpy.
- Hitta gräs-Y-fördelning. **OBS**: naturlig miljö har inte en ren is_grass-tröskel — gräs/jord/löv glider ihop i Y. Använd histogram + visuell verifiering, inte en enkel percentile.
- Sätt nya `Skimygrass` / `Skimycrown` defaults baserat på "var gräs DOMINERAR" (kan vara svårt — flagga för manuell tuning).

### Steg 4 — bypass ground_spread + merge_grass
- `Groundenable = 0` → merge_grass.bypass → tree direkt till OUT.
- (Alternativt: destroy ground_spread + select_ground_spread + merge_grass + nuvarande Ground-rattar för att rensa pipeline. Rek: BYPASS, behåll för senare återanvändning.)

**Vid detta steg är SWAP klar.** Användaren har ny miljö renderad med Skim-shimmer, hand-control, sliders, tree_radius_cull, tree_grass_thin. Spara som ny .toe-version. **Stoppa här om Spots/terrain-modulation på bakat gräs inte krävs.**

---

## Fas 3B — OMBYGGE (öppen tid, tid okänd tills ny PLY mätts)

**VARNING**: Detta är inte en swap. Det är ett ombygge i ny kontext med okända ytdata. Naturligt bakat gräs har ingen ren is_grass-tröskel — den faktiska svårigheten ligger i att isolera "bara gräset rör sig" utan att träd/stam/löv följer med eller blir partial-shimrade. Märk denna fas som "kräver mätning + iteration mot specifik PLY först". Estimera inte tid förrän nya miljöns gräs-isolation är förstådd.

### Steg 5 — Spots/terrain-relocation till tree-grenen (OMBYGGE, inte port)
Spots och terrain-noise applicerar nu HÖJDFÖRSKJUTNING på bakade gräs-punkter (inte på syntetiska som tidigare).

**Förutsättning**: ha kvantifierat hur ren is_grass-isolation går att göra på nya PLY:n. Möjliga metoder att utvärdera empiriskt:
- Y-threshold (`step(py, Skimycrown)`) — fungerar OM gräs ligger tydligt under övrigt
- Color-baserad mask (gräs-grönt vs jord-brunt vs löv) — om Color-attributet skiljer
- Hybrid: Y AND Color OR XZ-mask
- Manuell paint-mask via separat TOP → sampla per punkt

Vilken metod som fungerar beror på nya PLY:ns spridning. **STOPPA HÄR tills metoden är vald**.

Sedan **pipeline-insertion** mellan `cd_convert` och `extract_y` (eller mellan `apply_masked_noise` och `tree_grass_thin`):

```
cd_convert → tree_grass_mask (chosen method → is_grass-attribut) 
          → tree_terrain_coarse (noisePOP, samma config som ground_spread/terrain_coarse) 
          → tree_terrain_fine (noisePOP) 
          → tree_terrain_combine (mathcombinePOP: viktad summa) 
          → tree_spots_calc (3 spots eller 1 stor mathcombinePOP) 
          → tree_terrain_apply (mathcombinePOP: P.y += terrain.y * is_grass) 
          → extract_y (befintlig)
```

Återanvänd EXAKT samma ratter (Spot1xpos etc, Groundkullar, Groundmacroperiod) och samma op-konfiguration som i nuvarande `ground_spread`.

### Steg 6 — höjd-relativ shimmer (om kullar är högre än mask-band)
Per Fas 2d: nuvarande tree-shimmer använder absolut-Y-mask. Om Spot-amp > Skim-band-bredd → kullens topp över mask → mosaik.

Lösning: extend Fas 2d:s height-relative ground_noise-mönster till tree-grenen också. Skapa egen `tree_grass_shimmer` (kopia av nuvarande `apply_masked_noise` men med base_y-tracking) som applicerar shimmer relativt punktens base-höjd (innan terräng-offset).

Eller enklare: behåll y_clamp-mekanismen (klipp P.y vid Skimycrown - 0.005 efter terräng-apply) så shimmer-band alltid täcks.

### Steg 7 — verifiera
- Capture per steg.
- Hands-on-test: rotera, zooma, höj kullar live.
- fps regression check.
- Spara som `<NEW_ENV_NAME>.toe`.

## Vad som ÅTERANVÄNDS oförändrat

- `splat_control` — hand-tracking, sliders, joystick, Resetzoom/Resetlook.
- `handcam` med expression-bindings till `cam_position`.
- `mat_pointcolor` — material (alpha-justering kan behövas per miljö).
- `tree_radius_cull` + `tree_grass_thin` (om gäller — kanske ej för natural environment).
- `final_out` + `render1` + perform window.
- Hela Skim-page-rattarna + Spots/Ground rattarna (logiken flyttar men UI:t är samma).

## Vad som ÄNDRAS

- `treeply_in.par.file` (filsökväg)
- `Skimygrass` / `Skimycrown` defaults (Y-thresholds per miljö)
- `Groundenable = 0` (bypassa ground_spread)
- Spots+terrain-logik flyttas till tree-grenen (steg 5)

## Vad som EJ används längre (i ny miljö)

- `ground_spread` sub-COMP (bypassed, behåll för senare återanvändning eller delete)
- `select_ground_spread`, `merge_grass`'s input[1] (bypassed)
- Cirkulär disc-matta-konceptet

## Verifiering (capture-driven)

1. **Före swap**: capture baseline `.114_BEFORE.png`
2. **Efter PLY-swap**: capture, verifiera miljön renderas (alla 502k+ nya punkter syns)
3. **Efter Skim-Y-justering**: shimmer endast på gräs-Y, inte träd/krona
4. **Efter ground_spread bypass**: ingen cirkulär matta syns
5. **Efter Spots-relocation**: vrid Spot1amp → ser kullen på nya gräset
6. **Hands-on**: alla sliders/rotation funkar
7. fps stabil

## Risker

- **PLY-skala kan skilja**: iPhone-scan-storlek beror på hur scannen normaliseras. Kan behöva `splat_xform.scale` justering.
- **Y-orientation**: nya scan kanske har annan upp-axel (Y vs Z up). Verifiera via `splat_xform.rx/ry/rz`.
- **Color-skala**: ny baker måste ge 0-255 byte-Color som tree-pipelinen förväntar.
- **PointScale-värden**: nya PLY kan ha annan psize-fördelning → justera `pointscale_attr.attr0value0` (men den är bypassed i nuvarande projekt — verifiera flow).
- **Stora cooks vid PLY-load**: ny större PLY → potentiellt hang. Använd bypass-pattern under refactor.
- **Terräng-spots på bakade gräs (Steg 5) är okänt komplext**: kan vara enkel insert eller kräva is_grass-mask-tuning för att inte påverka kron/stam.

## Estimerad tidsåtgång

- Steg 0 (utanför TD): timmar (film + bake)
- Steg 1-4 (basic swap): 30 min
- Steg 5 (Spots-relocation): 1-2 timmar
- Steg 6 (shimmer-justering): 30 min
- Verifiering + iteration: 1 timme

Total: 3-5 timmar för clean swap, plus PLY-produktion separat.

## Build-säkerhet (per memory-lärdomar)

- **project.save() FIRST** mellan varje steg (flera TD-hangs riskerar förlust)
- Bygg deletePOP med bypass-först-pattern (configure först, unbypass sist) — bevisad i Fas 2c centerring-thin
- Sänk Grounddensity under refactor (300 → restore när stabilt)
- Använd MCP `set_parameter` per-parameter för stora bygg-batches (mindre cook-press än stora execute_python-blobs)

---

# FAKTISKT BYGGT — slutvärden från `hand_control_radon_tree.113.toe`

Snapshot av pipeline + ratter vid stop-point (2026-06-05). Använd dessa som referens för Fas 3-rekonstruktion.

## Pipeline-arkitektur (live state)

**Tree-gren** (inuti `/project1/GaussianSplatting/TreePoints/`):
```
treeply_in (RADON_Tree_baked.ply, 502 653 pts, thinstep=1)
  → splat_xform (T=(0,-0.6,0), R=(180,140,0))
  → pointscale_attr (bypassed)
  → cd_convert (attributeconvertPOP)
  → extract_y (mathcombinePOP, dot(P, yhat) → py)
  → compute_mask (mathPOP, py [-0.91,-0.85] → mask)
  → clamp_mask (mathcombinePOP, clamp(mask, 0, 1))
  → grass_noise (noisePOP simplex4d, amp/period/t4d bundna till Skim*)
  → apply_masked_noise (P += disp * mask)
  → tree_radius_cull (deletePOP, boundingbox XZ ±Treecullradius, Y unbounded)
  → tree_grass_thin (deletePOP, boundingbox tunn Y-band [-1, -0.84] XZ ±1.5, thinrandom=0.6)
  → merge_grass.input[0]
```

**Ground-gren** (inuti `/project1/GaussianSplatting/TreePoints/ground_spread/`):
```
disc (circlePOP, surface, radie=Groundradius)
  → sprinkle (sprinklePOP, density-baserad count)
  → flatten_y (mathcombinePOP, P.y = Groundy)
  → terrain_coarse (noisePOP, stora kullar)
  → terrain_fine (noisePOP, små knölar)
  → terrain_combine (mathcombinePOP, viktad summa → 'terrain', heightmap-hook-kommenterad)
  → terrain_apply (mathcombinePOP, P += terrain * (jitter, kullar, jitter))
  → spot1_calc (mathcombinePOP, smoothstep falloff → spot1_contrib)
  → spot2_calc (samma struktur)
  → spot3_calc (samma struktur)
  → spots_apply (mathcombinePOP, P.y += sum(spot_contrib))
  → ground_noise (noisePOP, UNCONDITIONAL shimmer på P, bundet till Skim*)
  → apply_ground_noise (P += disp_ground)
  → radius_attr (length(P.xz))
  → rand_noise (noisePOP för cull-decay)
  → keep_attr (mathcombinePOP, beräknar cull-score)
  → cull (deletePOP, attr-cond cull_score>0 OR radius outside)
  → set_color (Color = (255,255,255,Groundalpha))
  → set_ps (PointScale = Groundpointscale)
  → OUT
  
  → select_ground_spread → merge_grass.input[1]
```

**Slut**:
```
merge_grass → /project1/GaussianSplatting/TreePoints/OUT
            → render1 → bg_switch → final_out → /perform window
```

**Material**: `mat_pointcolor` (constantMAT, alpha=0.007, depthwriting=False, blending=True, applypointcolor=True, pointscaleattrib='PointScale')

## Custom-page rattar — slutvärden

### Skim-page (skimmer-mask + shimmer)
| Ratt | Värde |
|---|---|
| Skimamp | 0.0083 |
| Skimperiod | 1.01 |
| Skimspeed | 0.132 |
| Skimygrass | -0.91 |
| Skimycrown | -0.85 |

### Ground-page (gräs-spreadern + spots)
| Ratt | Värde | Default |
|---|---|---|
| Groundenable | 1 | 1 |
| Groundradius | 3.03 | 2.5 |
| Grounddensity | 10000 | 200 |
| Groundinnercut | 0.55 | 1.0 |
| Grounddecay | 0.166 | 0.5 |
| Groundy | -0.91 | -0.92 |
| Groundpointscale | 0.005 | 0.005 |
| Groundalpha | 30 | 11 |
| Groundjitter | 0.02 | 0.02 |
| Groundkullar | 0.05 | 0.05 |
| Groundmacroperiod | 12.8 | 6.0 |
| Groundmacroamt | 1.0 | 1.0 |
| Groundmicroperiod | 2.28 | 1.5 |
| Groundmicroamt | 0.4 | 0.4 |
| Spot1xpos | 1.5 | 0 |
| Spot1zpos | -2.15 | 0 |
| Spot1radius | 1.99 | 0.8 |
| Spot1amp | 0.195 | 0 |
| Spot2xpos | 1.76 | 0 |
| Spot2zpos | 1.11 | 0 |
| Spot2radius | 1.66 | 0.8 |
| Spot2amp | 0.135 | 0 |
| Spot3xpos | -3.51 | 0 |
| Spot3zpos | 0.06 | 0 |
| Spot3radius | 1.5 | 0.8 |
| Spot3amp | 0.159 | 0 |
| Treecullradius | 2.5 | 4.0 |
| Treeringthin | (skapades men hängde, ej i .113) | — |

## Render-statistik (slutläge)

- **Tree-grenens punkter**: 291 746 (efter radius_cull + grass_thin)
- **Ground-grenens punkter**: 235 028 (efter cull)
- **Total renderas**: 526 774
- **mat_pointcolor.alpha**: 0.007
- **fps-mål**: 60 (verifierat under bygget)

## .toe-versionshistorik (key milestones)

| Version | Innehåll |
|---|---|
| .93 | Innan Fas 2-bygge (baseline) |
| .94-.95 | Fas 2 (ground_spread MVP, 8 ratter) |
| .96-.97 | Fas 2b (oktav-terräng, 6 nya ratter) |
| .98-.99 | Fas 2c (3 spots + spots_apply) |
| .100-.103 | Fas 2d (höjd-relativ shimmer, ground_noise, y_clamp borttagen) |
| .104-.107 | Tuning (density, alpha, spot-positioner) |
| .108-.110 | tree_radius_cull (bakgrundsbrus-cull) |
| .111 | thinstep-experiment (reverterat) |
| **.113** | **Slutläge med tree_grass_thin (60% reduktion av vita ringen)** |

## Lärdomar för Fas 3-rekonstruktion

1. **bypass-först-pattern för deletePOPs**: skapa op, bypass omedelbart, configure utan cook, wire utan cook, unbypass sist. Hängde TD 3 gånger när vi gjorde det monolitiskt.
2. **PointScale, Color (vec4 0-255 byte-skala)** — bakad PLY-konvention, måste matchas av syntetiska punkter.
3. **Y-clamp via min-op fungerar komponent-vis** mot float3 i mathcombinePOP — bekräftat i Fas 2c stress-test.
4. **noisePOP `noise=True, combineop='none', noiseoutputattrscope='X'`** skapar X-attribut. Default combineop='add' kräver befintligt attr.
5. **mat_pointcolor.alpha påverkar BÅDA tree+ground** efter merge_grass. För selektiv dim, justera attribut-nivå per gren.
6. **TD hänger ofta vid samtidig topology-ändring + stora cooks**. Sänk Grounddensity till 200-300 under refactor.
7. **Memory: "starta om" = camera reset, inte TD restart**. Pulse Resetzoom + Resetlook.
