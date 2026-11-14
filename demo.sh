#!/usr/bin/env bash
# Live demo on a kind cluster with Agones 1.61 installed.
#
#   ./demo.sh reset            remove the demo objects
#   ./demo.sh apply            apply deploy/agones as it is on the current branch
#   ./demo.sh status           show the Fleet, the autoscaler and its events
#
# On main the autoscaler scales the Fleet from 1 to 2 servers. On the
# rename-counter-key branch the cluster accepts the change, the Fleet stays
# at 1 server and the autoscaler reports that the counter does not exist.
set -euo pipefail
cd "$(dirname "$0")"
NS=default

status() {
  echo "== Fleet"
  kubectl -n "$NS" get fleet arena -o custom-columns='NAME:.metadata.name,DESIRED:.spec.replicas,READY:.status.readyReplicas' 2>/dev/null || echo "(none)"
  echo
  echo "== FleetAutoscaler"
  kubectl -n "$NS" get fleetautoscaler arena-rooms -o custom-columns='NAME:.metadata.name,KEY:.spec.policy.counter.key,ABLE_TO_SCALE:.status.ableToScale,DESIRED:.status.desiredReplicas' 2>/dev/null || echo "(none)"
  echo
  echo "== Autoscaler events"
  kubectl -n "$NS" get events --field-selector involvedObject.name=arena-rooms \
    -o custom-columns='REASON:.reason,MESSAGE:.message' 2>/dev/null | cut -c1-160 | uniq | tail -4
}

case "${1:-status}" in
reset)
  kubectl -n "$NS" delete fleetautoscaler arena-rooms --ignore-not-found --wait
  kubectl -n "$NS" delete fleet arena --ignore-not-found --wait
  kubectl -n "$NS" delete events --field-selector involvedObject.name=arena-rooms >/dev/null 2>&1 || true
  ;;
apply)
  echo "\$ kubectl apply -f deploy/agones/ ($(git branch --show-current 2>/dev/null || echo '?'))"
  kubectl apply -f deploy/agones/
  echo "waiting 30s for the autoscaler..."
  sleep 30
  status
  ;;
status) status ;;
*) echo "usage: $0 reset|apply|status" >&2; exit 2 ;;
esac
