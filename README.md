<!-- SPDX-License-Identifier BSD-3-Clause -->
[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
---

# paperless install
This gh-project provide two solid methods for installing paperless and some 
additions like paperless-ai to an application-host. The methods are:

  * installing standalone als collection of containern inside podman pod
  * collection of templates and files for deploying with ansible as quadlets

Both methods require, that you installed podman on the deployment host. The
quadlet deployment also requires that the host uses systemd. If you will use
the provided container of paperless-ai you also need an OpenAPI compliant
AI-service (subscription) or local OpenAPI compliant service. paperless-ai
will not provide models. 

## Deploy standalone with script
This is the default method for deploying paperless-ngx. The script aims mostly
the original docker-compose file, but with some twists. The deploy process is
simple: just execute the installer.sh script insides this repo. You can also
execute the script direct from github:

```
    curl -s https://raw.githubusercontent.com/g4s/paperless-install/refs/heads/main/installer.sh | bash 
```
All optional parametes will be interactive asked. Secrets will use the podman
internal secret vault.

## Deploy quadlets with ansible [![Ansible](https://img.shields.io/badge/ansible-%231A1918.svg?style=for-the-badge&logo=ansible&logoColor=white)](https://docs.ansible.com)
The ansible based deploy is far more complicated, but integrates well if you
use ansible as an IaC-tool for your hole lab. The tasks 
---
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=963338797)