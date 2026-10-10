# oneagent-rollout

Rolls out the Dynatrace OneAgent to Acme Retail's web servers, through Dev, Test and Prod.
Terraform builds the servers, Ansible installs the agent, and GitHub Actions runs the stages in order.

## How to start a rollout

- **From a change:** edit a file under `terraform/envs/` or `ansible/` and push to `main`. The rollout starts by itself.
- **By hand:** Actions, **OneAgent rollout**, **Run workflow**, with the approved change ticket.

Each stage plans, then deploys: Terraform applies the reviewed plan, Ansible installs the agent in waves,
and a check confirms Dynatrace sees every server before the next stage starts.

## Who approves

- **Dev:** no approval needed.
- **Test and Prod:** a named reviewer approves the saved plan first.
  At a customer: the app owner for Test, the change manager for Prod.

## How to undo

- **Remove the agent:** on the runner, from the `ansible` folder: `ansible-playbook -i inventories/<env>/ remove-oneagent.yml`.
- **Undo a server change:** revert the commit. The next rollout plans the reverse.

## Lab only

- **Rebuild lab:** `rebuild` for fresh servers without the agent, `down` to delete them.
- **Pre-flight check:** confirms servers, access, the agent running on every server, and both tokens, before a rehearsal or the demo.

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
