# Thunderlands

Development setup for a Minecraft 1.21.1 Fabric server with separate server, client, and terrain-datapack dependencies. The setup script fetches dependencies from their publishers and verifies Modrinth file hashes before listing them in the generated lock file.

Review `server.properties.example` before copying it into a running server. It keeps secure profiles and the whitelist enabled. Use a disposable directory and review the downloaded mod set before running it.

```powershell
pwsh -File fetch-core.ps1
```

The script creates `local-build/` and downloads files over HTTPS. Use the generated lock files to inspect the exact versions selected during that run. This snapshot includes no player data, server secrets, binaries, or live runtime. The setup script was parsed for PowerShell errors before publication. The complete network install and multiplayer server were not exercised in this pass.
