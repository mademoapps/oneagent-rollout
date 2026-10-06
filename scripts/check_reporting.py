#!/usr/bin/env python3
"""Coverage check: AWS says N servers exist in this environment. Does Dynatrace see N?

Usage:  python3 scripts/check_reporting.py dev
Needs:  DT_ENV_URL and DT_READ_TOKEN (scope: entities.read), AWS access for the inventory
Exit 0 = all servers report. Exit 1 = stop the rollout.
"""
import json, os, re, subprocess, sys, time, urllib.parse, urllib.request

env = sys.argv[1]                         # dev, test or prod
host_group = f"acme-{env}"
base_url = os.environ["DT_ENV_URL"].rstrip("/")
token = os.environ["DT_READ_TOKEN"]

# 1. How many servers SHOULD report? Ask AWS through the Ansible inventory.
listing = subprocess.run(
    ["ansible", "all", "-i", f"ansible/inventories/{env}/", "--list-hosts"],
    capture_output=True, text=True, check=True).stdout
expected = int(re.search(r"hosts \((\d+)\)", listing).group(1))
if expected == 0:
    print(f"[{env}] FAIL: AWS lists no servers for this environment. Stopping the rollout.")
    sys.exit(1)

# 2. How many ARE reporting? Hosts in this host group seen in the last 5 minutes.
selector = (f'type(HOST),fromRelationships.isInstanceOf('
            f'type(HOST_GROUP),entityName.equals("{host_group}"))')
query = urllib.parse.urlencode({"entitySelector": selector, "from": "now-5m"})
request = urllib.request.Request(f"{base_url}/api/v2/entities?{query}",
                                 headers={"Authorization": f"Api-Token {token}"})

# 3. New agents take a minute or two to appear: ask every 15 s, for up to 5 minutes.
found = 0
for attempt in range(20):
    with urllib.request.urlopen(request, timeout=30) as response:
        found = json.load(response).get("totalCount", 0)
    print(f"[{env}] servers reporting to Dynatrace: {found} of {expected}")
    if found >= expected:
        print(f"[{env}] PASS: coverage {found}/{expected}")
        sys.exit(0)
    time.sleep(15)

print(f"[{env}] FAIL: only {found} of {expected} servers report. Stopping the rollout.")
sys.exit(1)