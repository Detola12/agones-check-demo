# agones-check demo

A tiny game backend used to demo [agones-check](https://github.com/Rohan-Muslekar/agones-check): one Fleet whose
servers track rooms with a Counter, and a FleetAutoscaler that scales on free rooms.

- `deploy/agones/`: the Agones manifests.
- `.github/workflows/agones-check.yml`: runs agones-check on every pull request that touches them.
- `demo.sh`: applies the manifests to a kind cluster and shows what the autoscaler does.

## The demo

1. **The mistake.** The pull request *rename-counter-key* changes the autoscaler's counter key from `rooms` to
   `sessions`. The Fleet has no `sessions` counter.
2. **Agones accepts it.** `kubectl apply --dry-run=server -f deploy/agones/` succeeds: the webhook checks each
   object on its own.
3. **agones-check blocks it.** The workflow fails with AC102 and annotates the changed line in the pull request.
4. **What would have happened.** On a kind cluster:

   ```sh
   git switch main && ./demo.sh reset && ./demo.sh apply           # Fleet scales 1 -> 2
   git switch rename-counter-key && ./demo.sh reset && ./demo.sh apply   # Fleet stays at 1, autoscaler errors
   ```

Requires a kind cluster with Agones 1.61:

```sh
kind create cluster --name agones-check
helm repo add agones https://agones.dev/chart/stable
helm install agones agones/agones --version 1.61.0 -n agones-system --create-namespace --wait
```
