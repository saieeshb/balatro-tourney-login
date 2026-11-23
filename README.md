<p align="center">
  <a href="https://balatro.saieesh.dev"><img src=".github/banner.png" width="100%" alt="Tourney Login: The Cavendish Cup's Balatro Multiplayer mod. No Steam needed. balatro.saieesh.dev"></a>
</p>

<p align="center">
  <a href="https://github.com/saieeshb/balatro-tourney-login/releases/latest/download/TourneyLogin.zip"><img alt="Download TourneyLogin.zip" src="https://img.shields.io/badge/download-TourneyLogin.zip-FFCB21?style=for-the-badge&labelColor=2B1606"></a>
  <a href="https://balatro.saieesh.dev"><img alt="Player site: balatro.saieesh.dev" src="https://img.shields.io/badge/player_site-balatro.saieesh.dev-1F6CC0?style=for-the-badge&labelColor=0A2547"></a>
  <a href="LICENSE"><img alt="Licence: GPL-3.0" src="https://img.shields.io/badge/licence-GPL--3.0-23804A?style=for-the-badge&labelColor=0B331C"></a>
</p>

Tourney Login is the companion mod for **[The Cavendish Cup](https://balatro.saieesh.dev)**, a free, unofficial Balatro PvP tournament. It runs alongside [Balatro Multiplayer](https://github.com/Balatro-Multiplayer/BalatroMultiplayerPvP), and its mod id is `NoSteamLogin`.

**Playing in the tournament?** Everything you need, from registering to joining a match, is at **[balatro.saieesh.dev](https://balatro.saieesh.dev)**. [PLAYERS.md](PLAYERS.md) has the same steps.

## What it does

<img src=".github/spade.svg" width="20" height="20" alt=""> **Points the game at the tournament server**, `balatro.saieesh.dev`. This happens in memory only and never changes Multiplayer API's own settings, so disabling the mod puts the game back on the official server.

<img src=".github/heart.svg" width="20" height="20" alt=""> **Logs in without the Steam client.** The mod saves a login id in the Balatro save folder (`nosteam_login_id.txt`), so you keep the same account every launch. If Steam is running, it uses your Steam account instead.

<img src=".github/diamond.svg" width="20" height="20" alt=""> **Lets you pick your name.** In game, go to **Mods → Tourney Login → Config**, type it, press **Save name**, and restart the game.

It never logs in to the official server without Steam, because that server checks real Steam tickets.

## Install

### <img src=".github/chip-1.svg" width="32" height="32" alt=""> Get the multiplayer mods

Install **BET** from [balatromp.com/download](https://balatromp.com/download) and point it at your game. In your BET profile, add **Multiplayer PvP**, which brings **Multiplayer API** with it. Both need to be **1.0.7 or newer**.

### <img src=".github/chip-2.svg" width="32" height="32" alt=""> Add Tourney Login

Download **[TourneyLogin.zip](https://github.com/saieeshb/balatro-tourney-login/releases/latest/download/TourneyLogin.zip)**. In BET, click **+ Add Local Mod**, choose the zip, and make sure **Tourney Login** is in your profile.

### <img src=".github/chip-3.svg" width="32" height="32" alt=""> Set your name

Press **Run**, open **Mods → Tourney Login → Config**, type the name you registered with, press **Save name**, and restart the game.

Not using BET? Put Steamodded, Lovely, Multiplayer API, Multiplayer PvP and the `TourneyLogin` folder from the zip in your `Mods` folder yourself.

## Settings

These live in `config.lua`:

| Key | Default | Meaning |
|---|---|---|
| `server_host` | `balatro.saieesh.dev` | Tournament server. Set it to `''` to use Multiplayer API's own setting. |
| `server_port` | `443` | |
| `server_secure` | `true` | Uses TLS. |
| `display_name` | `''` | Set this in game instead. |

If Multiplayer API's own `use_custom_server` setting is on, it overrides the server set here. The organiser's own machine uses that to connect locally.

The name you save in game goes to `config/NoSteamLogin.jkr` in the save folder. Only the name is saved there, so a later change to the server settings still reaches every player.

## Test

```sh
luajit tests/provider_test.lua path/to/MultiplayerAPI
```

This loads the API's real `steam.lua`, `dev.lua` and `lifecycle.lua` with the game stubbed out. It then checks which server and login each setup gets: default, custom server, and preset off. It also checks the saved name.

## Licence

GNU General Public License v3.0. See [LICENSE](LICENSE).

The Cavendish Cup is an unofficial community tournament, not affiliated with LocalThunk or Playstack.
