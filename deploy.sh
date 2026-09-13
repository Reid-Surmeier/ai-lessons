#!/usr/bin/env bash
# Publish this site to https://ai.reidsurmeier.wtf/ (nginx static root on the droplet).
set -euo pipefail
cd "$(dirname "$0")"
rsync -az --delete --exclude .git --exclude deploy.sh --exclude README.md ./ droplet:/var/www/ai.reidsurmeier.wtf/
curl -fsS -o /dev/null -w 'https://ai.reidsurmeier.wtf/ %{http_code}\n' --resolve ai.reidsurmeier.wtf:443:172.67.186.192 https://ai.reidsurmeier.wtf/telephone/
