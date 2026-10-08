#!/usr/bin/env bash
# Usage: ./run.sh  (needs a local PostgreSQL; set PGHOST/PGPORT/PGUSER if not default)
set -e
createdb leadfunnel 2>/dev/null || true
psql -q -d leadfunnel -f sql/01_schema_load.sql
psql -q -d leadfunnel -f sql/02_clean_view.sql
psql -q -d leadfunnel -f sql/04_export.sql
echo "Done. Run: streamlit run app.py"
