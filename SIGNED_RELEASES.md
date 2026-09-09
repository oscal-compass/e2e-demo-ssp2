# Signed SSP releases

The `main` release workflow rebuilds the SSP and publishes `ssp-package-<tag>.tar.gz`. The package contains the SSP, its profile, catalog, Ubuntu component definition, `ssp-signing-manifest.json`, and the detached `ssp-signing-manifest.dsse` envelope.

Trestle canonicalizes every listed JSON artifact using RFC 8785, records its SHA-256 digest in an in-toto Statement, and signs that Statement using the configured encrypted PEM private key. The workflow verifies the package before publishing it.

## Repository configuration

Generate an encrypted Ed25519 key pair:

```bash
read -rsp 'Signing key password: ' SSP_SIGNING_KEY_PASSWORD
export SSP_SIGNING_KEY_PASSWORD
openssl genpkey -algorithm ED25519 -aes-256-cbc \
  -pass env:SSP_SIGNING_KEY_PASSWORD \
  -out ssp-private.pem
openssl pkey -in ssp-private.pem \
  -passin env:SSP_SIGNING_KEY_PASSWORD \
  -pubout \
  -out ssp-public.pem
chmod 600 ssp-private.pem
```

Configure the GitHub Actions secrets through the repository settings or with the GitHub CLI:

```bash
gh secret set SSP_SIGNING_PRIVATE_KEY < ssp-private.pem
printf '%s' "$SSP_SIGNING_KEY_PASSWORD" | gh secret set SSP_SIGNING_KEY_PASSWORD
gh secret set SSP_SIGNING_PUBLIC_KEY < ssp-public.pem
unset SSP_SIGNING_KEY_PASSWORD
```

The required secrets are:

- `SSP_SIGNING_PRIVATE_KEY`: the encrypted PEM private key used to sign the SSP package;
- `SSP_SIGNING_KEY_PASSWORD`: the private-key password;
- `SSP_SIGNING_PUBLIC_KEY`: the public key used for verification before publication.

Consumers must obtain the trusted public key independently from the release being verified.

## Verification

Download and extract `ssp-package-<tag>.tar.gz`, then run:

```bash
trestle verify-manifest \
  --beta \
  --manifest ssp-signing-manifest.json \
  --signature ssp-signing-manifest.dsse \
  --public-key trusted-ssp-public.pem
```

Verification checks the DSSE signature and confirms that every current artifact matches the SHA-256 digest recorded in the signed package Statement.
