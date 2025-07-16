<!-- SPDX-License-Identifier BSD-3-Clause -->
[![License](https://img.shields.io/badge/License-BSD_3--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
---

# paperless install [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=963338797) [![GitHub issues](https://img.shields.io/github/issues/g4s/paperless-intall)](https://github.com/g4s/paperless-install/issues)
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
use ansible as an IaC-tool for your hole lab. Also it will not produce a
standalone pod with containers - it will produced quadlets, a way to manage
container with systemd.

For integrating this repo into your IaC, it is necessary to place the file
structure under [ansible/](./ansible) inside your Iac-repo, cause I not
encapsulated the code as ansible-role. For things like this, I personally
highly recommend tools like [gilt - the git layering tool](https://github.com/retr0h/gilt).
Inside your playbook you should refference the tasks something similar,
like this:

```yaml
 - hosts: applicationhost
   vars:
     paperless_ai_support: true
     paperless_authentik_auth: true
     paperless_authentik_url: "https://auth.example.com"
   tasks:
     - ansible.builtin.inlclude_tasks:
         file: "services/paperless.yaml"
```

A full list of all ansible vars is provided inside [ansible/README.md](ansible/README.md).
The ansible play is tested against Fedora/Alma/RHEL other distribution will 
maybe work, but are not tested.
