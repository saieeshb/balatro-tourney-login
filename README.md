# Tourney Login

A small companion mod for [Balatro Multiplayer](https://github.com/Balatro-Multiplayer/BalatroMultiplayerPvP) (mod id `NoSteamLogin`). It does three things:

1. **Points the game at the tourney server**, `balatro.saieesh.dev`. This happens in memory only and never changes Multiplayer API's own settings, so disabling this mod puts the game back on the official server.
2. **Logs in without the Steam client.** The mod saves a login id in the Balatro save folder (`nosteam_login_id.txt`), so you keep the same account every launch. If Steam is running, it uses your Steam account instead.
3. **Lets you pick your name:** in game, go to **Mods → Tourney Login → Config**, type it, press **Save name**, and restart the game.

It never logs in to the official server without Steam. That server checks real Steam tickets.

**Download:** [TourneyLogin.zip](https://github.com/saieeshb/balatro-tourney-login/releases/latest/download/TourneyLogin.zip), the latest release. Players should follow [PLAYERS.md](PLAYERS.md) for setup.

## Needs

- Steamodded and Lovely
- **Multiplayer API 1.0.7 or newer**, plus Multiplayer PvP

## Settings

These live in `config.lua`:

| Key | Default | Meaning |
|---|---|---|
| `server_host` | `balatro.saieesh.dev` | Tourney server. Set it to `''` to use Multiplayer API's own setting. |
| `server_port` | `443` | |
| `server_secure` | `true` | Uses TLS. |
| `display_name` | `''` | Set this in game instead. |

If Multiplayer API's own `use_custom_server` setting is on, it overrides the server set here. The host uses that to connect locally.

The name you save in game goes to `config/NoSteamLogin.jkr` in the save folder. Only the name is saved there, so a later change to the server settings still reaches every player.

## Test

```sh
luajit tests/provider_test.lua path/to/MultiplayerAPI
```

This loads the API's real `steam.lua`, `dev.lua` and `lifecycle.lua` with the game stubbed out. It then checks which server and login each setup gets: default, custom server, and preset off. It also checks the saved name.

## Licence

GNU General Public License v3.0. See [LICENSE](LICENSE).
