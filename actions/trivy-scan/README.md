# Trivy Security Scan Action

Scan Docker container images for vulnerabilities using [Aqua Security Trivy](https://github.com/aquasecurity/trivy).

## Features

- 🔍 Scan container images for vulnerabilities (OS packages and application dependencies)
- 🔒 Detect secrets and misconfigurations
- 📊 Multiple output formats (SARIF, JSON, Table)
- 🎯 Configurable severity levels
- 📤 Upload results to GitHub Security tab
- 🗃️ Store results as artifacts
- ⚠️ Non-blocking by default (warnings only)

## Usage

### Basic Usage

```yaml
- name: Run Trivy security scan
  uses: marcelpiva-org/maestroai-github-actions/actions/trivy-scan@main
  with:
    image: ghcr.io/marcelpiva-org/maestro-chat-app:latest
```

### Advanced Usage

```yaml
- name: Run Trivy security scan
  uses: marcelpiva-org/maestroai-github-actions/actions/trivy-scan@main
  with:
    image: ghcr.io/marcelpiva-org/maestro-chat-app:v1.2.3
    severity: 'CRITICAL,HIGH'
    exit_code: '1'  # Fail pipeline on vulnerabilities
    format: 'sarif'
    output_file: 'trivy-results.sarif'
    upload_sarif: 'true'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `image` | Container image to scan (registry/name:tag) | ✅ Yes | - |
| `severity` | Severity levels to report | No | `CRITICAL,HIGH` |
| `exit_code` | Exit code when vulnerabilities found (0 = non-blocking) | No | `0` |
| `format` | Output format (table, json, sarif) | No | `sarif` |
| `output_file` | Output file path | No | `trivy-results.sarif` |
| `upload_sarif` | Upload SARIF results to GitHub Security | No | `true` |

## Outputs

| Output | Description |
|--------|-------------|
| `vulnerabilities_found` | Number of vulnerabilities found |

## Severity Levels

- `CRITICAL` - Critical vulnerabilities (CVE score 9.0-10.0)
- `HIGH` - High vulnerabilities (CVE score 7.0-8.9)
- `MEDIUM` - Medium vulnerabilities (CVE score 4.0-6.9)
- `LOW` - Low vulnerabilities (CVE score 0.1-3.9)
- `UNKNOWN` - Unknown severity

## Output Formats

### SARIF (Default)
- Best for GitHub Security integration
- Viewable in GitHub Security tab
- Supports code annotations

### Table
- Human-readable format
- Best for logs and terminal output
- Shows vulnerability details

### JSON
- Machine-readable format
- Best for automation and parsing
- Complete vulnerability data

## Examples

### Scan and Upload to GitHub Security

```yaml
steps:
  - name: Scan container
    uses: marcelpiva-org/maestroai-github-actions/actions/trivy-scan@main
    with:
      image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
      severity: 'CRITICAL,HIGH,MEDIUM'
      format: 'sarif'
      upload_sarif: 'true'
```

### Fail Pipeline on Critical Vulnerabilities

```yaml
steps:
  - name: Scan container (blocking)
    uses: marcelpiva-org/maestroai-github-actions/actions/trivy-scan@main
    with:
      image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
      severity: 'CRITICAL'
      exit_code: '1'  # Fail if CRITICAL found
```

### Scan with Table Output for Logs

```yaml
steps:
  - name: Scan container (table output)
    uses: marcelpiva-org/maestroai-github-actions/actions/trivy-scan@main
    with:
      image: myapp:latest
      format: 'table'
      severity: 'HIGH,CRITICAL'
```

## Integration with Microservice Workflow

The Trivy scan is automatically integrated in the `dotnet-microservice.yml` workflow:

```yaml
jobs:
  trivy-scan:
    needs: [create-manifest]
    runs-on: maestroai-runners
    steps:
      - uses: marcelpiva-org/maestroai-github-actions/actions/trivy-scan@main
        with:
          image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ needs.setup-dependencies.outputs.version_tag }}
```

## Viewing Results

### GitHub Security Tab
1. Navigate to your repository
2. Click **Security** tab
3. Click **Code scanning alerts**
4. Filter by **trivy-container-scan**

### Artifacts
Scan results are stored as artifacts for 30 days:
1. Navigate to workflow run
2. Click **Artifacts** section
3. Download `trivy-scan-results-*`

## Best Practices

### Non-Blocking Mode (Recommended for Initial Setup)
```yaml
exit_code: '0'  # Non-blocking, shows warnings
```

### Blocking Mode (Production)
```yaml
exit_code: '1'  # Fail pipeline on vulnerabilities
severity: 'CRITICAL,HIGH'  # Only critical and high
```

### Scan Multiple Images
```yaml
strategy:
  matrix:
    image:
      - app:latest
      - worker:latest
steps:
  - uses: .../trivy-scan
    with:
      image: ${{ matrix.image }}
```

## Troubleshooting

### Scan Times Out
```yaml
# Increase timeout in trivy-action
timeout: '15m'
```

### False Positives
Create `.trivyignore` file in repository:
```
# Ignore specific CVE
CVE-2021-12345

# Ignore by path
/usr/lib/libssl.so
```

### Private Registries
Trivy uses Docker credentials from previous login step.

## Related Actions

- [docker-build](../docker-build/) - Build Docker containers
- [setup-dotnet](../setup-dotnet/) - Setup .NET environment

## References

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [GitHub Security](https://docs.github.com/en/code-security)
- [SARIF Format](https://sarifweb.azurewebsites.net/)
