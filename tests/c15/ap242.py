import re

SCHEMA = 'AP242_MANAGED_MODEL_BASED_3D_ENGINEERING_MIM_LF'


def split_entities(text):
    data = text.split('DATA;\n', 1)[1].rsplit('ENDSEC;', 1)[0]
    ents = {}
    for chunk in data.split(';\n'):
        chunk = chunk.strip()
        if not chunk:
            continue
        m = re.match(r'#(\d+)\s*=\s*(.*)$', chunk, re.S)
        assert m, f'bad entity line: {chunk[:80]}'
        eid = int(m.group(1))
        assert eid not in ents, f'duplicate entity id {eid}'
        body = m.group(2).strip()
        assert body.count('(') == body.count(')'), f'unbalanced parens in #{eid}'
        ents[eid] = body
    return ents


def refs_of(body):
    return [int(x) for x in re.findall(r'#(\d+)', body)]


def check_refs(ents):
    for eid, body in ents.items():
        for r in refs_of(body):
            assert r in ents, f'#{eid} references missing #{r}'


def check_contiguous(ids):
    ids = sorted(ids)
    assert ids == list(range(ids[0], ids[0] + len(ids))), 'PMI ids not contiguous'


def find(ents, name):
    return {i: b for i, b in ents.items() if name in b}


def read_pmi(path):
    text = open(path).read()
    assert SCHEMA in text.split('ENDSEC;', 1)[0], 'AP242 schema missing from header'
    ents = split_entities(text)
    check_refs(ents)
    datums = {}
    for i, b in find(ents, 'DATUM(').items():
        if 'DATUM_REFERENCE' in b or 'DATUM_FEATURE' in b:
            continue
        m = re.match(r"\(DATUM\('((?:''|[^'])*)'\)SHAPE_ASPECT\('','',#(\d+),\.F\.\)\)$",b)
        assert m, f'bad DATUM complex #{i}: {b[:100]}'
        datums[m.group(1).replace("''", "'")] = {'id': i, 'pds': int(m.group(2))}
    features = {}
    for i, b in find(ents, 'DATUM_FEATURE()').items():
        m = re.match(r"\(DATUM_FEATURE\(\)SHAPE_ASPECT\('df-((?:''|[^'])*)','([^']*)',#(\d+),\.T\.\)\)$",b)
        assert m, f'bad DATUM_FEATURE complex #{i}: {b[:100]}'
        features[m.group(1).replace("''", "'")] = {'id': i, 'sel': m.group(2)}
    for i, b in find(ents, 'SHAPE_ASPECT_RELATIONSHIP(').items():
        m = re.match(r"SHAPE_ASPECT_RELATIONSHIP\('','',#(\d+),#(\d+)\)$",b)
        assert m, f'bad relationship #{i}: {b[:100]}'
    dims = {}
    for i, b in find(ents, 'DIMENSIONAL_SIZE(').items():
        m = re.match(r"DIMENSIONAL_SIZE\(#(\d+),'((?:''|[^'])*)'\)$",b)
        assert m, f'bad DIMENSIONAL_SIZE #{i}: {b[:100]}'
        dims[m.group(2).replace("''", "'")] = {'id': i, 'sa': int(m.group(1))}
    measures = {}
    for i, b in ents.items():
        if 'MEASURE_REPRESENTATION_ITEM()' in b:
            m = re.match(r"\(MEASURE_REPRESENTATION_ITEM\(\)MEASURE_WITH_UNIT\(LENGTH_MEASURE\(([^)]*)\),#(\d+)\)REPRESENTATION_ITEM\('([^']*)'\)\)$",b)
            assert m, f'bad measure item #{i}: {b[:100]}'
            measures[i] = (float(m.group(1)), int(m.group(2)), m.group(3))
    reps = {}
    for i, b in find(ents, 'SHAPE_DIMENSION_REPRESENTATION()').items():
        if 'INDEPENDENT_LIMITS' in b or 'DIMENSIONAL_CHARACTERISTIC_REPRESENTATION' in b:
            continue
        m = re.match(r"\(REPRESENTATION\('([^']*)',\(#(\d+)\),#(\d+)\)SHAPE_DIMENSION_REPRESENTATION\(\)SHAPE_REPRESENTATION\(\)\)$",b)
        assert m, f'bad dimension rep #{i}: {b[:100]}'
        reps[i] = (m.group(1), int(m.group(2)), int(m.group(3)))
    for i, b in find(ents, 'INDEPENDENT_LIMITS_OF_LINEAR_DIMENSIONAL_SIZE_CHARACTERISTIC_REPRESENTATION').items():
        m = re.match(r"\(DIMENSIONAL_CHARACTERISTIC_REPRESENTATION\(#(\d+),#(\d+)\)INDEPENDENT_LIMITS_OF_LINEAR_DIMENSIONAL_SIZE_CHARACTERISTIC_REPRESENTATION\(\(#(\d+),#(\d+)\)\)\)$",b)
        assert m, f'bad limits rep #{i}: {b[:100]}'
        ds, nom, lo, hi = int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4))
        name = next(n for n, d in dims.items() if d['id'] == ds)
        dims[name]['nom'] = measures[reps[nom][1]][0]
        dims[name]['lo'] = measures[reps[lo][1]][0]
        dims[name]['hi'] = measures[reps[hi][1]][0]
    tols = {}
    for i, b in find(ents, 'FLATNESS_TOLERANCE(').items():
        m = re.match(r"FLATNESS_TOLERANCE\('((?:''|[^'])*)','flatness',#(\d+),#(\d+)\)$",b)
        assert m, f'bad FLATNESS_TOLERANCE #{i}: {b[:100]}'
        tols[m.group(1).replace("''", "'")] = {'kind': 'flatness', 'mag': int(m.group(2)),
                                               'sa': int(m.group(3)), 'dr': []}
    for i, b in find(ents, 'GEOMETRIC_TOLERANCE_WITH_DATUM_REFERENCE(').items():
        m = re.match(r"\(GEOMETRIC_TOLERANCE\('((?:''|[^'])*)','([^']*)',#(\d+),#(\d+)\)GEOMETRIC_TOLERANCE_WITH_DATUM_REFERENCE\(\(#(\d+)\)\)(PERPENDICULARITY_TOLERANCE|PARALLELISM_TOLERANCE)\(\)\)$",b)
        assert m, f'bad orientation tolerance #{i}: {b[:120]}'
        kind = 'perpendicularity' if m.group(6).startswith('PERP') else 'parallelism'
        assert m.group(2) == kind, f'description/kind mismatch #{i}'
        tols[m.group(1).replace("''", "'")] = {'kind': kind, 'mag': int(m.group(3)),
                                               'sa': int(m.group(4)), 'dr': [int(m.group(5))]}
    aspects = {}
    for i, b in find(ents, "SHAPE_ASPECT('tol-face'").items():
        m = re.match(r"SHAPE_ASPECT\('tol-face','([^']*)',#(\d+),\.T\.\)$",b)
        assert m, f'bad tol-face aspect #{i}: {b[:100]}'
        aspects[i] = m.group(1)
    for t in tols.values():
        t['sel'] = aspects[t['sa']]
        mag = ents[t['mag']]
        m = re.match(r"\(LENGTH_MEASURE_WITH_UNIT\(\)MEASURE_WITH_UNIT\(LENGTH_MEASURE\(([^)]*)\),#(\d+)\)\)$",mag)
        assert m, f'bad magnitude #{t["mag"]}: {mag[:100]}'
        t['val'] = float(m.group(1))
        dns = []
        for d in t['dr']:
            m = re.match(r'DATUM_REFERENCE\(1,#(\d+)\)$',ents[d])
            assert m, f'bad DATUM_REFERENCE #{d}'
            dns.append(next(n for n, x in datums.items() if x['id'] == int(m.group(1))))
        t['datums'] = dns
        del t['mag'], t['sa'], t['dr']
    for n, d in datums.items():
        d['sel'] = features[n]['sel']
        del d['pds']
    pmi_ids = [d['id'] for d in datums.values()] + [x['id'] for x in features.values()] \
        + [d['id'] for d in dims.values()] + list(measures) + list(reps) \
        + [i for i, b in ents.items() if 'INDEPENDENT_LIMITS' in b or 'FLATNESS_TOLERANCE' in b
           or 'GEOMETRIC_TOLERANCE_WITH_DATUM_REFERENCE' in b or 'DATUM_REFERENCE(' in b
           or "SHAPE_ASPECT('tol-face'" in b or 'SHAPE_ASPECT_RELATIONSHIP(' in b
           or "SHAPE_ASPECT('size'" in b or 'LENGTH_MEASURE_WITH_UNIT(' in b]
    pmi_ids = sorted(set(pmi_ids))
    check_contiguous(pmi_ids)
    return {'datums': {n: d['sel'] for n, d in datums.items()},
            'dims': {n: (d['nom'], d['lo'], d['hi']) for n, d in dims.items()},
            'tols': {n: (t['kind'], t['val'], t['sel'], t['datums']) for n, t in tols.items()},
            'base': min(pmi_ids), 'count': len(pmi_ids)}


def geom_entities(path, skip_names=('APPLICATION_CONTEXT(', 'APPLICATION_PROTOCOL_DEFINITION(')):
    text = open(path).read()
    ents = split_entities(text)
    return {i: b for i, b in ents.items()
            if not any(n in b for n in skip_names)
            and 'DATUM' not in b and 'TOLERANCE' not in b and 'DIMENSIONAL_' not in b
            and 'MEASURE_REPRESENTATION_ITEM' not in b and 'SHAPE_DIMENSION_REPRESENTATION' not in b
            and "SHAPE_ASPECT('tol-face'" not in b and "SHAPE_ASPECT('size'" not in b
            and 'SHAPE_ASPECT_RELATIONSHIP(' not in b and 'LENGTH_MEASURE_WITH_UNIT(' not in b}
