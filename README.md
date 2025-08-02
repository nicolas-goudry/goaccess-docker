# GoAccess Docker Images

[![Built with Nix](https://img.shields.io/badge/built_with_Nix-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/nicolas-goudry/goaccess-docker/release.yml)](https://github.com/nicolas-goudry/goaccess-docker/actions/workflows/release.yml)
[![License](https://img.shields.io/badge/license-MIT-pink)](./LICENSE)

This project provides a **Nix-based collection of [GoAccess](https://goaccess.io) Docker images**, with 36+ variants across multiple Linux distributions and with optional geolocation support.

**For GoAccess usage instructions, configuration options, and detailed documentation, please visit the [official GoAccess website](https://goaccess.io/) and [documentation](https://goaccess.io/man).**

## Quick start

```bash
# Latest version of GoAccess
docker run --rm ghcr.io/nicolas-goudry/goaccess-docker/goaccess:latest --version

# Latest version of GoAccess with GeoLite2 databases built-in and configured
docker run --rm ghcr.io/nicolas-goudry/goaccess-docker/goaccess:latest-geolite2 --version
```

## Images

### Tags

For a complete list of available tags, refer to [GitHub Packages](https://github.com/nicolas-goudry/goaccess-docker/pkgs/container/goaccess-docker%2Fgoaccess).

Tags are formatted as follows:

```plain
<version>-<geo-variant>-<distro>
```

Where:

- `<version>` is the GoAccess version
- `-<geo-variant>` is the optional [geolocation variant](#geolocation-variants)
- `-<distro>` is the optional [base distribution](#base-distributions)

> [!NOTE]
>
> For convenience, `<version>` can be set to `latest` to target the latest available GoAccess version.

### Geolocation variants

Each base distribution comes in three geolocation configurations:

| Variant      | Suffix                | Description                                      |
| ------------ | --------------------- | ------------------------------------------------ |
| **Base**     | _none_                | GoAccess without geolocation support             |
| **GeoIP**    | `-geoip`              | Geolocation support (requires external database) |
| **GeoLite2** | `-geolite2-<version>` | Includes bundled GeoLite2 database               |

> [!NOTE]
>
> GeoLite2 databases come from [this repository](https://github.com/P3TERX/GeoLite.mmdb) and are updated automatically via a recurring [GitHub Actions workflow](./.github/workflows/update-geolite.yml).
>
> The `-<version>` field of GeoLite2 variant can be omitted when using published images, it will then use the latest available GeoLite2 variant.

#### Choosing the right variant

- **Base variants**: no geolocation support, smallest size
- **GeoIP variants**: support for geolocation with external MaxMind database
- **GeoLite2 variants**: ready to use GeoLite2 database (city database)

### Base distributions

| Distribution    | Tag suffix     | Description                 |
| --------------- | -------------- | --------------------------- |
| **Distroless**  | _none_         | Minimal scratch-based image |
| **Alpine**      | `-alpine`      | Alpine Linux 3.22           |
| **Debian**      | `-debian`      | Debian 12 (Bookworm)        |
| **Debian Slim** | `-debian-slim` | Minimal Debian 12           |
| **Ubuntu**      | `-ubuntu`      | Ubuntu 25.04                |

> [!NOTE]
>
> The tag suffixes above are the main ones. There are aliases available.

#### Choosing the right variant

| Scenario              | Recommended variant      | Reason                                 |
| --------------------- | ------------------------ | -------------------------------------- |
| Production deployment | Distroless               | Minimal size, maximum security         |
| Development/testing   | Alpine                   | Good balance of size and functionality |
| Complex integrations  | Debian/Ubuntu            | Full Linux environment                 |
| CI/CD pipelines       | Distroless or Alpine     | Fast startup, minimal overhead         |
| Debugging issues      | Alpine, Debian or Ubuntu | Shell access for troubleshooting       |

## Development

### Prerequisites

- [Nix](https://nixos.org/download/)
- [Docker](https://docs.docker.com/engine/install/) or [Podman](https://podman.io/docs/installation#installing-on-linux) (for testing)

### Building

```bash
# Build images
nix build                         # Distroless base
nix build .#distroless-geoip      # Distroless with GeoIP
nix build .#alpine                # Alpine base
nix build .#alpine-geoip          # Alpine with GeoIP
nix build .#alpine-geolite2       # Alpine with GeoLite2
nix build .#debian-slim-geolite2  # Debian slim with GeoLite2

# Build and load into Docker/Podman
nix build .#alpine.copyToDockerDaemon
nix build .#alpine.copyToPodman

# Build GeoLite2 package
nix build .#geolite2
```

<details>

<summary>No Flakes? Got you covered.</summary>

```bash
# Build images
nix-build --attr default               # Distroless base
nix-build --attr distroless-geoip      # Distroless with GeoIP
nix-build --attr alpine                # Alpine base
nix-build --attr alpine-geoip          # Alpine with GeoIP
nix-build --attr alpine-geolite2       # Alpine with GeoLite2
nix-build --attr debian-slim-geolite2  # Debian slim with GeoLite2

# Load into Docker/Podman
nix-build --attr default.copyToDockerDaemon
./result/bin/copy-to-docker-daemon
nix-build --attr default.copyToPodman
./result/bin/copy-to-podman

# Build GeoLite2 package
nix-build --attr geolite2
```

</details>

### Testing

```bash
# Test basic functionality
nix run .#alpine.copyToDockerDaemon
docker run --rm goaccess:1.9.4-alpine --version

# Test with sample logs
echo '127.0.0.1 - - [01/Aug/2025:12:00:00 +0000] "GET / HTTP/1.1" 200 1234 "" ""' > test.log
docker run -it --rm -v $(pwd):/logs goaccess:1.9.4-alpine /logs/test.log --log-format=COMBINED
```

> [!NOTE]
>
> The `goaccess:1.9.4-alpine` tag is created locally after building, thanks to `copyToDockerDaemon`.
>
> To use pre-built images from GitHub Packages, use the `ghcr.io/nicolas-goudry/goaccess-docker/goaccess:...` format.

### Project structure

<!-- Generated with: "tree --noreport -a -L1 --dirsfirst --gitignore -I '.git*' -I '*.lock' -I '*.md' -I '.env*' -I 'LICENSE'" -->

```
.
├── .hooks
│   └── pre-commit.sh  # Shared pre-commit Git hook, installed automatically with builtin devshell
├── lib
│   ├── default.nix    # Core image building functions
│   └── distros.nix    # Base image definitions
├── pkgs
│   └── geolite2.nix   # GeoLite2 database package
├── default.nix        # Build outputs
├── flake.nix          # Nix flake configuration
├── shell.nix          # Nix devshell
└── treefmt.nix        # Nix formatter
```

### Key functions

- `mkImage`: main function to build GoAccess images
- `mkAllImages`: creates the complete image matrix

> [!NOTE]
>
> Functions are located in the [`lib` directory](./lib).

### Adding new base images

1. Add the base image to `lib/distros.nix`:

```nix
mylinux = {
  imageName = "mylinux";
  imageDigest = "sha256:95a416ad2446813278ec13b7efdeb551190c94e12028707dd7525632d3cec0d1"; # Get from image metadata or registry
  sha256 = "sha256-..."; # Get with: nix-prefetch-docker
};
```

2. The build system automatically generates all variants

### Updating dependencies

```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake update nixpkgs

# Update GeoLite2
nix run .#geolite2.passthru.updateScript
# nix-build --attr geolite2.passthru.updateScript
# ./result/bin/geolite2-update
```

## License

This project is licensed under the [MIT License](./LICENSE).
