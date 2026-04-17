# searxng Helm chart

This chart deploys SearXNG on Kubernetes and follows the current upstream container layout: a writable `/etc/searxng`, a persistent `/var/cache/searxng`, and an optional built-in Valkey service for limiter and public-instance features.

## Included features

- SearXNG Deployment and Service
- Optional built-in Valkey Deployment and Service
- Writable runtime config volume with generated `settings.yml`
- Optional extra config files such as `limiter.toml` and `favicons.toml`
- Optional Ingress
- Optional Gateway API `HTTPRoute`
- Optional custom CA certificates mount
- Generated runtime secret for `SEARXNG_SECRET`

## Defaults

The defaults are aimed at a single private instance behind a reverse proxy:

- 1 replica
- built-in Valkey enabled
- writable ephemeral config volume
- persistent cache PVC enabled
- generated `SEARXNG_SECRET`
- `server.method=GET`
- `server.image_proxy=true`
- Ingress and Gateway API disabled by default

## Install with Helm 3

Add the repository after GitHub Pages is enabled and the first release has been published:

```bash
helm repo add searxng https://techpipe-io.github.io/searxng-helm-chart
helm repo update
```

Install with defaults:

```bash
helm upgrade --install searxng searxng/searxng --namespace search --create-namespace
```

Install with an override file:

```bash
helm upgrade --install searxng searxng/searxng --namespace search --create-namespace -f values.override.yaml
```

Render manifests locally:

```bash
helm template searxng ./charts/searxng -f ./charts/searxng/examples/values.override.yaml
```

## Install with Helmwave

Example `helmwave.yml`:

```yaml
repositories:
  - name: searxng
    url: https://techpipe-io.github.io/searxng-helm-chart

releases:
  - name: searxng
    namespace: search
    create_namespace: true
    chart:
      name: searxng/searxng
      version: 0.1.0
    values:
      - ./values.override.yaml
```

Apply:

```bash
helmwave build
helmwave up
```

## Typical override file

A ready example is included at [examples/values.override.yaml](examples/values.override.yaml).

## Main values

### Runtime environment

- `env.forceOwnership`
- `env.values`
- `env.secretValues`
- `env.existingSecrets`
- `env.existingConfigMaps`

`env.values` and `env.secretValues` are the catch-all mechanisms for additional `SEARXNG_*`, `GRANIAN_*`, or other container environment variables.

### SearXNG config

The chart generates `settings.yml` from:

```yaml
config:
  useDefaultSettings: true
  settings: {}
```

Extra non-secret config files go into `config.files`.

Extra secret config files go into `config.secretFiles`.

Examples:

```yaml
config:
  files:
    limiter.toml: |
      [botdetection.ip_lists]
      block_ip = []
```

```yaml
config:
  secretFiles:
    settings.yml: |
      use_default_settings: true
      server:
        base_url: https://search.example.com/
        secret_key: replace-me
```

If `config.secretFiles["settings.yml"]` is provided, it overrides the generated `settings.yml`.

### Secrets

The chart can generate `SEARXNG_SECRET` automatically.

You can also bring your own secret:

```yaml
secret:
  create: false
  existingSecret: searxng-runtime
  existingSecretKey: SEARXNG_SECRET
```

### Persistence

- `persistence.config.*` controls `/etc/searxng`
- `persistence.cache.*` controls `/var/cache/searxng`
- `valkey.persistence.*` controls `/data` for built-in Valkey

By default, config is ephemeral and cache is persistent.

### Valkey

The chart follows the current upstream direction and enables a built-in Valkey instance by default.

Use an external Valkey service:

```yaml
valkey:
  enabled: false
  externalUrl: valkey://my-valkey.default.svc.cluster.local:6379/0
```

Or reference a secret containing a full URL:

```yaml
valkey:
  enabled: false
  externalUrlSecret:
    name: searxng-runtime
    key: SEARXNG_VALKEY_URL
```

If you enable built-in Valkey auth, the chart computes and injects the internal `SEARXNG_VALKEY_URL` automatically.

### Custom CA certificates

Inline certificates:

```yaml
caCertificates:
  files:
    corp-root.crt: |
      -----BEGIN CERTIFICATE-----
      ...
      -----END CERTIFICATE-----
```

Or mount an existing ConfigMap or Secret:

```yaml
caCertificates:
  existingConfigMap: corp-ca
```

## Ingress example

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
  hosts:
    - host: search.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: search-example-com-tls
      hosts:
        - search.example.com
config:
  settings:
    server:
      base_url: https://search.example.com/
```

## Gateway API example

The chart creates an `HTTPRoute`, not a `Gateway`.

```yaml
ingress:
  enabled: false
gateway:
  enabled: true
  parentRefs:
    - name: public
      namespace: infra
      sectionName: https
  hostnames:
    - search.example.com
config:
  settings:
    server:
      base_url: https://search.example.com/
```

