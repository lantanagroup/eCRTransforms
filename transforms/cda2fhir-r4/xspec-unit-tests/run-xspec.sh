#!/bin/bash
# 20260729 Claude: XSpec runner for the cda2fhir suite.
#
# Why this exists: the suite had not been run since ~2025-03 and nobody had recorded HOW to run
# it, so the first job was archaeology. This script is that archaeology, written down.
#
#   ./run-xspec.sh                 # run every *.xspec, print a pass/fail summary
#   ./run-xspec.sh Organization    # only files whose name contains this substring
#
# Requirements (both fetched automatically into .xspec-tools/ on first run):
#   * Saxon-HE 10.9      - NOT 11/12: those need xmlresolver on the classpath as well.
#   * XSpec 4.0.3        - taken from Maven Central (io.xspec:xspec), because GitHub source
#                          archives are not reachable from every environment. The jar contains
#                          the whole XSLT framework under io/xspec/xspec/impl/src/.
#   * Java 17+.
#
# The .xspec files point at ../NativeUUIDGen-cda2fhir.xslt, not ../SaxonPE-cda2fhir.xslt.
# SaxonPE calls java:java.util.UUID.randomUUID(), which Saxon-HE cannot do ("Reflexive calls to
# Java methods are not available under Saxon-HE"), so the suite could not run on a free Saxon at
# all. The two entry points differ ONLY in how UUIDs are minted; everything downstream is the
# same stylesheet. Production is unaffected - it still uses cda2fhir.xslt / SaxonPE.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLS="$HERE/.xspec-tools"
OUT="$HERE/.xspec-results"
FILTER="${1:-}"
SAXON="$TOOLS/saxon-he-10.9.jar"
XSPEC_JAR="$TOOLS/xspec-4.0.3.jar"
XSPEC_SRC="$TOOLS/xspec/io/xspec/xspec/impl/src"

mkdir -p "$TOOLS" "$OUT"
[ -f "$SAXON" ] || { echo "fetching Saxon-HE 10.9..."; curl -sSL -o "$SAXON" \
  https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/10.9/Saxon-HE-10.9.jar || exit 2; }
[ -f "$XSPEC_JAR" ] || { echo "fetching XSpec 4.0.3..."; curl -sSL -o "$XSPEC_JAR" \
  https://repo1.maven.org/maven2/io/xspec/xspec/4.0.3/xspec-4.0.3.jar || exit 2; }
[ -d "$XSPEC_SRC" ] || { mkdir -p "$TOOLS/xspec" && (cd "$TOOLS/xspec" && unzip -q -o "$XSPEC_JAR"); }

fail_total=0; pass_total=0; files=0
for spec in "$HERE"/*.xspec; do
  base=$(basename "$spec" .xspec)
  [ -n "$FILTER" ] && [[ "$base" != *"$FILTER"* ]] && continue
  files=$((files+1))
  if ! java -cp "$SAXON" net.sf.saxon.Transform -s:"$spec" \
        -xsl:"$XSPEC_SRC/compiler/compile-xslt-tests.xsl" \
        -o:"$OUT/$base-compiled.xsl" 2>"$OUT/$base-compile.err"; then
    echo "COMPILE-FAIL  $base"; sed -n '1,3p' "$OUT/$base-compile.err"; fail_total=$((fail_total+1)); continue
  fi
  if ! java -cp "$SAXON" net.sf.saxon.Transform \
        -it:'{http://www.jenitennison.com/xslt/xspec}main' -xsl:"$OUT/$base-compiled.xsl" \
        -o:"$OUT/$base-result.xml" 2>"$OUT/$base-run.err"; then
    echo "RUN-FAIL      $base"; tail -n 3 "$OUT/$base-run.err"; fail_total=$((fail_total+1)); continue
  fi
  read -r p f <<<"$(python3 - "$OUT/$base-result.xml" <<'PY'
import sys, xml.etree.ElementTree as ET
NS='{http://www.jenitennison.com/xslt/xspec}'
t=ET.parse(sys.argv[1]); tests=t.iter(NS+'test')
p=f=0
for x in tests:
    if x.get('successful')=='true': p+=1
    else: f+=1
print(p, f)
PY
)"
  pass_total=$((pass_total+p)); fail_total=$((fail_total+f))
  printf '%-42s pass=%-4s fail=%-3s%s\n' "$base" "$p" "$f" "$([ "$f" != 0 ] && echo '  <-- FAILURES')"
done
echo
echo "$files file(s): $pass_total assertions passed, $fail_total failed"
echo "results + compiled stylesheets in $OUT (gitignored)"
[ "$fail_total" = 0 ]
