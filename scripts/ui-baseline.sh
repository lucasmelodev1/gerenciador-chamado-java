#!/usr/bin/env bash
# S1 — Baseline capture (UI-REWRITE-PLAN.md §3 / S1).
#
# Captures the pre-rewrite state so that P0's gate and S18's final acceptance
# can be compared against a known-good snapshot:
#   baseline/git-head.txt      commit under capture
#   baseline/assets.list       34 templates + 5 project CSS + 6 project JS = 45 files
#   baseline/assets.sha256     integrity hashes of those 45 files
#   baseline/build-app.log     docker compose build app
#   baseline/test-suite.log    docker compose run --rm test  (mvn verify: tests + JaCoCo gate)
#   baseline/coverage.txt      line coverage of the JaCoCo-included reserva classes
#   baseline/war-contents.txt  WAR payload (proves static assets ship)
#   baseline/tooolchain.txt    host toolchain note (best effort, never a gate)
#
# Deviations from the plan text are recorded in baseline/EVIDENCE.md.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
OUT="baseline"
mkdir -p "$OUT"

log() { printf '[S1] %s\n' "$*"; }

log "recording git state"
git rev-parse HEAD > "$OUT/git-head.txt"
git status --porcelain > "$OUT/git-status.txt"

log "hashing the 45 own frontend assets"
{
    find src/main/webapp -type f \( -name '*.jsp' -o -name '*.jspf' \) | sort
    find src/main/resources/static/css -maxdepth 1 -type f -name '*.css' | sort
    find src/main/resources/static/js -maxdepth 1 -type f -name '*.js' | sort
} > "$OUT/assets.list"
xargs -a "$OUT/assets.list" sha256sum > "$OUT/assets.sha256"

log "docker compose build app"
docker compose build app > "$OUT/build-app.log" 2>&1
tail -n 3 "$OUT/build-app.log"

log "running the full suite + coverage gate (mvn verify)"
if ! docker compose run --rm test sh -c '
        mvn -B verify
        rc=$?
        echo "--- jacoco line coverage (reserva classes in pom.xml includes) ---"
        awk -F, "NR>1 {lm+=\$8; lc+=\$9} END {printf \"LINE_COVERED=%d LINE_MISSED=%d LINE_RATIO=%.4f\n\", lc, lm, lc/(lc+lm)}" \
            target/site/jacoco/jacoco.csv
        exit $rc
    ' > "$OUT/test-suite.log" 2>&1; then
    log "SUITE FAILED — tail of $OUT/test-suite.log:"
    tail -n 40 "$OUT/test-suite.log"
    exit 1
fi

log "extracting coverage summary"
grep 'LINE_COVERED=' "$OUT/test-suite.log" | tail -n 1 | tee "$OUT/coverage.txt"

log "capturing WAR contents"
docker compose run --rm --no-deps --entrypoint jar app tf /app/app.war | sort > "$OUT/war-contents.txt"

log "noting host toolchain (best effort; Docker is the authoritative toolchain)"
{
    echo "java: $(java -version 2>&1 | head -n 1)"
    echo "node: $(node -v)"
    echo "npm:  $(npm -v)"
    echo
    echo "NOTE: the host has no JDK 21 (project target). All gates run in Docker"
    echo "      (maven:3.9.9-eclipse-temurin-21 / eclipse-temurin:21-jdk-jammy)."
} > "$OUT/toolchain.txt"

log "summarising"
{
    echo "# Baseline snapshot (S1)"
    echo
    echo "- Commit: \`$(cat "$OUT/git-head.txt")\`"
    echo "- Assets hashed: **$(wc -l < "$OUT/assets.sha256")**"
    echo "- Suite: \`$(grep -E 'Tests run:.*Failures' "$OUT/test-suite.log" | tail -n 1 | sed 's/^\[INFO\] //')\`"
    echo "- Coverage: \`$(cat "$OUT/coverage.txt")\`"
    echo "- WAR entries: **$(wc -l < "$OUT/war-contents.txt")**"
    echo "- Static CSS in WAR: \`$(grep -c 'static/css/' "$OUT/war-contents.txt")\` entries"
    echo
    echo "Regenerate with \`bash scripts/ui-baseline.sh\` (idempotent)."
} > "$OUT/README.md"

log "done — see $OUT/README.md"
cat "$OUT/README.md"
