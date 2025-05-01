# Traefik

This guide gives you a step by step instruction on how to install Traefik including its Dashboard, Cert-Manager (for certificates) and an Issuer (Let's Encrypt) for INWX.

## Requirements

* RKE2 is already set up and running

## Installation

The initial installation was done with the [deploy.sh-Script][def] by [JimsGarage][def2]. In that script all components are installed by applying .yaml-files to your kubernetes cluster. I strongly recommend watching his [video][def3] for further explanations.  
Since I prefer the use of helm charts, I switched my installation to helm. See the [Upgrade-Guide](../Upgrade/Readme.md) for details.

## Configuration

The following steps my be done after the initial installation.

The default cluster issuer does not support [INWX][def4] which is my DNS provider. Fortunately we can use [this][def5] helm chart to make it work. See Step 11 in the [deploy.sh-script][def].

[def]: ./deploy.sh
[def2]: https://github.com/JamesTurland/JimsGarage
[def3]: https://www.youtube.com/watch?v=XH9XgiVM_z4&pp=ygUSamltc2dhcmFnZSB0cmFlZmlr
[def4]: https://www.inwx.de
[def5]: https://gitlab.com/smueller18/cert-manager-webhook-inwx