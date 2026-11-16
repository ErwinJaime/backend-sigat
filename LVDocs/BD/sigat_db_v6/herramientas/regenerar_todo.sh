#!/bin/bash
# Regenera el paquete a partir del DBML v6 (requiere python3 y graphviz para los diagramas).
# 1) transform.py: v5 -> v6 (prefijos de 4 letras, sin ICA)  [ya aplicado; produce ../diagramas/sigat.dbml y meta.json]
# 2) gen_paquete.py: SQL, documentación, DBML por área y .dot
cd "$(dirname "$0")"
python3 transform.py sigat_v5.dbml ../diagramas/sigat.dbml meta.json
python3 gen_paquete.py ../diagramas/sigat.dbml meta.json explicacion_v5.md ..
cd ../diagramas && for f in er_*.dot; do b=${f%.dot}; dot -Tsvg $f -o $b.svg; dot -Tpng -Gdpi=110 $f -o $b.png; done
