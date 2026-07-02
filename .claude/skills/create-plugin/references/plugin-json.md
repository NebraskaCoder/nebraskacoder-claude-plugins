# `plugin.json` reference

The plugin manifest lives at `<plugin>/.claude-plugin/plugin.json`. Only this
file goes inside `.claude-plugin/`; all component directories live at the plugin
root and are auto-discovered.

## Fields

| Field           | Type            | Required | Notes |
|-----------------|-----------------|----------|-------|
| `name`          | string          | **Yes**  | kebab-case identifier. Namespaces components as `/<name>:<component>`. Must match the plugin's entry `name` in `marketplace.json`. |
| `version`       | string          | No*      | Semver. If omitted, Claude Code uses the git commit SHA. Bump it to deliver updates. Always set it. |
| `description`   | string          | No*      | One-line purpose. Shown in `/plugin` UI. Always set it. |
| `author`        | object          | No*      | `{ "name", "email", "url" }`. Always set it. |
| `displayName`   | string          | No       | Human-readable name for UI; falls back to `name`. |
| `homepage`      | string          | No       | Docs URL. |
| `repository`    | string          | No       | Source URL. |
| `license`       | string          | No       | SPDX id. This repo's default is `Unlicense` (public domain); see the repo `LICENSE`. |
| `keywords`      | array<string>   | No       | Discovery tags. |
| `defaultEnabled`| boolean         | No       | Whether the plugin starts enabled after install. Default true. |
| `$schema`       | string          | No       | JSON Schema URL for editor validation. |

\* Not required by the loader, but this repo's convention is to always include
`version`, `description`, `author`, and `license` (`Unlicense`).

### Component path overrides (usually unnecessary)

These point Claude Code at non-default locations and **supplement** the
auto-discovered defaults — they do not replace them. Only include a key when the
plugin keeps that component somewhere other than the standard directory. Values
may be a string or an array of strings.

| Field         | Default location        |
|---------------|-------------------------|
| `commands`    | `commands/`             |
| `agents`      | `agents/`               |
| `skills`      | `skills/`               |
| `hooks`       | `hooks/hooks.json`      |
| `mcpServers`  | `.mcp.json`             |

Because the defaults are auto-discovered, a plugin using standard layout should
**omit** all of these keys.

## Complete example

```json
{
  "$schema": "https://json.schemastore.org/claude-code-plugin-manifest.json",
  "name": "my-plugin",
  "version": "0.1.0",
  "description": "Does something genuinely useful.",
  "author": {
    "name": "NebraskaCoder",
    "email": "nebraskacoder@gmail.com",
    "url": "https://github.com/NebraskaCoder"
  },
  "homepage": "https://github.com/NebraskaCoder/nebraskacoder-claude-plugins",
  "repository": "https://github.com/NebraskaCoder/nebraskacoder-claude-plugins",
  "license": "Unlicense",
  "keywords": ["productivity"]
}
```

## Marketplace entry (in root `.claude-plugin/marketplace.json`)

Every plugin also needs an entry appended to the `plugins` array of the root
marketplace catalog. `source` is relative to the **repo root**:

```json
{
  "name": "my-plugin",
  "source": "./plugins/my-plugin",
  "description": "Does something genuinely useful.",
  "version": "0.1.0"
}
```

The `name` here must exactly match the manifest `name`.
