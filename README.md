# oneagent-rollout
## Kubernetes (shown, not run in the demo)

The Dynatrace Operator puts the agent on every node, including new ones.
Its settings live in `kubernetes/dynakube-dev.yaml`.

```bash
# Once per cluster: install the Operator
helm install dynatrace-operator oci://public.ecr.aws/dynatrace/dynatrace-operator \
  --create-namespace --namespace dynatrace --atomic

# The token comes from the secrets store, never from Git
kubectl -n dynatrace create secret generic dynakube --from-literal="apiToken=<operator token>"

# Apply the settings file from Git. In production, Argo CD or Flux does this step.
kubectl apply -f kubernetes/dynakube-dev.yaml
```
