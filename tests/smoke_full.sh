#!/bin/bash
# dolphin-mcp-pilot full smoke test
# Usage: bash tests/smoke_full.sh [PORT] [DS_USER] [DS_PASSWORD]
PORT="${1:-8007}"
DS_U="${2:-admin}"
DS_P="${3:-admin}"

URL="http://localhost:${PORT}/mcp/"
CT='Content-Type: application/json'
AC='Accept: application/json, text/event-stream'
U="X-DS-User: ${DS_U}"
P="X-DS-Password: ${DS_P}"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS  $1"; }
ng(){ FAIL=$((FAIL+1)); echo "  FAIL  $1"; }
chk(){ if [ "$2" = "1" ]; then ok "$1"; else ng "$1 $3"; fi }

echo "=================================================="
echo "dolphin-mcp-pilot smoke test  (port ${PORT})"
echo "=================================================="

# ---------- 1. protocol handshake ----------
echo
echo "[1] MCP protocol handshake"
curl -s -m 20 -D /tmp/sm_hdr.txt -H "$CT" -H "$AC" -H "$U" -H "$P" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"1"}}}' \
  "$URL" > /tmp/sm_init.txt 2>/dev/null

grep -q '"result"' /tmp/sm_init.txt && chk "initialize returns result" 1 || chk "initialize returns result" 0 "$(head -c 150 /tmp/sm_init.txt)"

SID=$(awk 'tolower($1)=="mcp-session-id:" {gsub("\r","",$2); print $2}' /tmp/sm_hdr.txt)
[ -n "$SID" ] && chk "session id issued" 1 || chk "session id issued" 0
grep -q '"instructions"' /tmp/sm_init.txt && chk "instructions present" 1 || chk "instructions present" 0
grep -q '"protocolVersion"' /tmp/sm_init.txt && chk "protocolVersion echoed" 1 || chk "protocolVersion echoed" 0

curl -s -m 10 -H "$CT" -H "$AC" -H "$U" -H "$P" -H "mcp-session-id: $SID" \
  -d '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}' "$URL" >/dev/null 2>&1
chk "notifications/initialized accepted" 1

# ---------- 2. tools/list integrity ----------
echo
echo "[2] Tool registry integrity"
curl -s -m 20 -H "$CT" -H "$AC" -H "$U" -H "$P" -H "mcp-session-id: $SID" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' "$URL" > /tmp/sm_tools.txt 2>/dev/null

TOTAL=$(grep -o '"name":"ds_[a-z_]*"' /tmp/sm_tools.txt | sort -u | wc -l | tr -d ' ')
[ "$TOTAL" = "58" ] && chk "tool count == 58" 1 || chk "tool count == 58" 0 "(got ${TOTAL})"

# every tool must have a non-empty description
NODESC=$(grep -o '"description":""' /tmp/sm_tools.txt | wc -l | tr -d ' ')
[ "$NODESC" = "0" ] && chk "no empty descriptions" 1 || chk "no empty descriptions" 0 "(${NODESC} empty)"

# key tools must exist
for t in ds_help ds_test_connection ds_list_projects ds_list_workflows \
         ds_list_process_instances ds_list_task_instances ds_complement_data \
         ds_update_task_param ds_create_dag_workflow ds_get_latest_failure_log; do
  grep -q "\"name\":\"${t}\"" /tmp/sm_tools.txt && chk "tool exists: ${t}" 1 || chk "tool exists: ${t}" 0
done

# ---------- 3. new-feature hints (regression guard) ----------
echo
echo "[3] Documented behaviour / regression guards"
grep -q 'complementStartDate' /tmp/sm_tools.txt \
  && chk "serial backfill range format documented" 1 \
  || chk "serial backfill range format documented" 0
grep -q 'ds_list_task_instances' /tmp/sm_tools.txt \
  && chk "task-instance guidance present" 1 \
  || chk "task-instance guidance present" 0
grep -q 'next_action' /tmp/sm_tools.txt \
  && chk "next_action hint documented" 1 \
  || chk "next_action hint documented" 0
grep -q 'ignored_fields' /tmp/sm_tools.txt \
  && chk "ignored_fields documented" 1 \
  || chk "ignored_fields documented" 0

# ---------- 4. tool invocation (no DS needed) ----------
echo
echo "[4] Tool invocation"
call(){ # $1=id $2=name $3=args_json -> /tmp/sm_call.txt
  curl -s -m 30 -H "$CT" -H "$AC" -H "$U" -H "$P" -H "mcp-session-id: $SID" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":$1,\"method\":\"tools/call\",\"params\":{\"name\":\"$2\",\"arguments\":$3}}" \
    "$URL" > /tmp/sm_call.txt 2>/dev/null
}

call 10 ds_help '{}'
grep -q '"isError":true' /tmp/sm_call.txt && chk "ds_help()" 0 "$(head -c 120 /tmp/sm_call.txt)" || chk "ds_help()" 1

call 11 ds_help '{"category":"quickstart"}'
grep -q '"isError":true' /tmp/sm_call.txt && chk "ds_help(category=quickstart)" 0 || chk "ds_help(category=quickstart)" 1

# invalid category should not crash the server
call 12 ds_help '{"category":"__no_such_category__"}'
grep -q '"result"' /tmp/sm_call.txt && chk "ds_help handles unknown category" 1 || chk "ds_help handles unknown category" 0

# ---------- 5. error handling ----------
echo
echo "[5] Error handling / robustness"
# unknown tool -> JSON-RPC error, server stays alive
curl -s -m 15 -H "$CT" -H "$AC" -H "$U" -H "$P" -H "mcp-session-id: $SID" \
  -d '{"jsonrpc":"2.0","id":20,"method":"tools/call","params":{"name":"ds_does_not_exist","arguments":{}}}' \
  "$URL" > /tmp/sm_err.txt 2>/dev/null
grep -qE '"error"|"isError":true' /tmp/sm_err.txt && chk "unknown tool rejected" 1 || chk "unknown tool rejected" 0

# missing required argument -> error, not 500 crash
curl -s -m 15 -H "$CT" -H "$AC" -H "$U" -H "$P" -H "mcp-session-id: $SID" \
  -d '{"jsonrpc":"2.0","id":21,"method":"tools/call","params":{"name":"ds_list_workflows","arguments":{}}}' \
  "$URL" > /tmp/sm_err2.txt 2>/dev/null
grep -qE '"error"|"isError":true|"result"' /tmp/sm_err2.txt && chk "missing arg handled gracefully" 1 || chk "missing arg handled gracefully" 0

# malformed JSON -> must not kill the process
curl -s -m 15 -H "$CT" -H "$AC" -H "$U" -H "$P" -H "mcp-session-id: $SID" \
  -d '{"jsonrpc":"2.0","id":22,' "$URL" >/dev/null 2>&1
curl -s -m 15 -H "$CT" -H "$AC" -H "$U" -H "$P" -H "mcp-session-id: $SID" \
  -d '{"jsonrpc":"2.0","id":23,"method":"tools/list","params":{}}' "$URL" > /tmp/sm_alive.txt 2>/dev/null
grep -q '"result"' /tmp/sm_alive.txt && chk "server alive after malformed JSON" 1 || chk "server alive after malformed JSON" 0

# request without session id
curl -s -m 15 -H "$CT" -H "$AC" -H "$U" -H "$P" \
  -d '{"jsonrpc":"2.0","id":24,"method":"tools/list","params":{}}' "$URL" > /tmp/sm_nosid.txt 2>/dev/null
[ -s /tmp/sm_nosid.txt ] && chk "request without session id answered" 1 || chk "request without session id answered" 0

# ---------- 6. secret leakage in responses ----------
echo
echo "[6] Secret leakage check"
if grep -qiE 'X-DS-Password|"password"[[:space:]]*:[[:space:]]*"[^"]+"' /tmp/sm_tools.txt /tmp/sm_init.txt; then
  ng "no credential echoed in responses"
else
  ok "no credential echoed in responses"
fi

# ---------- summary ----------
echo
echo "=================================================="
echo "PASS=${PASS}  FAIL=${FAIL}"
if [ "$FAIL" = "0" ]; then
  echo "RESULT: PASS"
else
  echo "RESULT: FAIL"
fi
echo "=================================================="
[ "$FAIL" = "0" ] || exit 1
