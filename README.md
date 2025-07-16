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

## Deploy standaline with script