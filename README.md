# Deborah

This Gitlab project builds the following Debian packages:

 * [X] the Linux kernel
 * [X] RTL8723DS Wifi
 * [ ] RTL8723DS Bluetooth
 * [ ] Mali 3d drivers

The following NTC boards are supported:
 * [X] CHIP 4
 * [ ] CHIP PRO
 * [ ] CHIP classic

## Parameters

The followning environment variables are used:

  - `AWS_BUCKET`: S3 bucket name where repository is published
  - `AWS_REGION`: AWS region for S3 bucket
  - `AWS_ACCES_KEY_ID`: AWS id
  - `AWS_SECRET_ACCESS_KEY`: secret AWS key
  - `LINUX_DEPLOY_PRIVATE_KEY`: unencrypted ssh key to access Linux repository
  - `LINUX_REPO`: URL of the Linux repository to build
  - `LINUX_BRANCH`: Linux branch to build from
  - `LINUX_CONFIG`: Linux configuration file (relative to LINUX_REPO)
  - `GPG_PRIVATE_KEY`: unencrypted gpg secret key used for repository signing

The build might fail if they are not set correctly.

## How to publish repository on S3

All variables starting with `AWS_` must be defined - otherwise the publishing
step is skipped.

TODO:
 - explain how to create a public AWS bucket accessible via https
 - explain how to create a AWS user & role (give role example)

## How to use private Linux Git repository

Sometime it's not possible make the Linux repository public, because of support for still top-secret product in there.
The `LINUX_REPO` variable should be an SSH URL, e.g. `git@github.com:yourname/linux` and the *unencrypted* private SSH
key to access that repository needs to be defined as `LINUX_DEPLOY_PRIVATE_KEY`.
In Github the corresponding public key needs to be added as a deployment key.

## How to create signed Debian repository

In order to create a signed repository, the  `GPG_PRIVATE_KEY` variable needs to
contain an *unencrypted* GPG secret key.
Using `gpg` version 2, an unencrypted GPG secret key can be created and
exported using these commands:
```
gpg --pinentry-mode loopback --full-generate-key
gpg --export-secret-key --armor >secret.key
```

