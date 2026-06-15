# Nix cache lookup

Check if a flake attribute is already cached in any of the flake's
configured binary caches.

Reads `nixConfig.extra-substituters` from the
flake and checks each cache via the [Nix binary cache
protocol](https://nix.dev/manual/nix/2.18/protocols/binary-cache-store)
(`GET <base-url>/<hash>.narinfo`).

## Usage

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v27
        with:
          extra_nix_config: |
            access-tokens = github.com=${{ secrets.GH_ACCESS_TOKEN }}
      - uses: cachix/cachix-action@v15
        with:
          name: opensource
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'

      - name: Check if already cached
        uses: damianfral/nix-cache-lookup@v1
        id: nix-cache-lookup
        with:
          flake-attribute: .#backend

      - name: Build (if not cached)
        run: nix build -L .#backend --accept-flake-config
        if: steps.nix-cache-lookup.outputs.cached != 'true'
```

## Inputs

| Name                  | Required | Default | Description                                |
| --------------------- | -------- | ------- | ------------------------------------------ |
| `flake-attribute`     | ✅       | —       | Flake attribute to check, e.g. `.#foo`     |
| `working-directory`   | ❌       | `.`     | Directory containing the flake             |

## Outputs

| Name          | Description                                         |
| ------------- | --------------------------------------------------- |
| `cached`      | `'true'` if found in any cache, `'false'` otherwise |
| `store-hash`  | The Nix store hash of the evaluated attribute       |

## How it works

1. Evaluates `nix eval <flake-attribute>.outPath --raw` to get the Nix
  store path. Fails if evaluation fails.
2. Extracts the store hash from the path.
3. Collects a deduplicated list of substituters to check, including:
  - `https://cache.nixos.org`
  - System-configured substituters (from `nix show-config`)
  - Flake-configured `substituters` and `extra-substituters` (from `nixConfig`)
4. For each URL, performs a `GET` request fo
5. If any cache responds with HTTP 200, the attribute is considered cached.
