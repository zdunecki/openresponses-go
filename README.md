# openresponses-go

Standalone Go package for [OpenResponses](https://www.openresponses.org/) API, automatically extracted from [openai/openai-go](https://github.com/openai/openai-go).

> ⚠️ **Warning**: This is not an official OpenResponses library. It's a workaround until official SDK support is available. See [openresponses/openresponses#36](https://github.com/openresponses/openresponses/discussions/36) for the discussion on official SDK support.

## Installation

```bash
go get github.com/zdunecki/openresponses-go/v3
```

## Usage

```go
import "github.com/zdunecki/openresponses-go/v3/responses"
```

## Sync with upstream

This repository automatically syncs with the official `openai/openai-go` repository:

- Runs daily via GitHub Actions
- Extracts only the `responses` package and its dependencies
- Creates a PR with the changelog from upstream
- Tags match the upstream version

## License

This project uses a dual license:

- **Go source code** (extracted from [openai/openai-go](https://github.com/openai/openai-go)): [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)
- **Build scripts & workflows** (script.sh, .github/*, README.md): [MIT License](https://opensource.org/licenses/MIT)

See [license](license) for full details.
