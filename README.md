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
This is the default method for deploy paperless-ngx

## Deploy quadlets with ansible
---
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?hide_repo_select=true&ref=main&repo=963338797)