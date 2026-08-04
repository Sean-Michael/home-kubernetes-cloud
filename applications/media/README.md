# Media stack (Plex + arrs)

ArgoCD-managed media server stack, pinned to **caliban** because that's where
the GPU and `/data` live. Everything stateful is a hostPath under `/data`, so
the whole cluster can be torn down (game mode) and rebuilt without losing any
config or media.

## Apps & where to reach them

| App         | Purpose               | LAN URL                    | Tailnet                          |
|-------------|-----------------------|----------------------------|----------------------------------|
| Plex        | media server          | http://caliban:32400/web   | (hostNetwork, use LAN/plex.tv)   |
| Overseerr   | request management    | http://caliban:30055       | overseerr.tail4dd976.ts.net      |
| Sonarr      | TV automation         | http://caliban:30989       | sonarr.tail4dd976.ts.net         |
| Radarr      | movie automation      | http://caliban:30878       | radarr.tail4dd976.ts.net         |
| Prowlarr    | indexer manager       | http://caliban:30696       | prowlarr.tail4dd976.ts.net       |
| qBittorrent | download client       | http://caliban:30080       | qbittorrent.tail4dd976.ts.net    |
| Tautulli    | Plex stats            | http://caliban:30181       | tautulli.tail4dd976.ts.net       |

## Storage layout (on caliban)

```
/data/appdata/<app>   # per-app /config (databases, settings)
/data/media/movies    # Plex "Movies" library / Radarr root folder
/data/media/tv        # Plex "TV" library / Sonarr root folder
/data/media/music     # Plex "Music" library
/data/media/downloads # qBittorrent save path
```

All containers mount `/data/media` as `/media` — one volume, so Sonarr/Radarr
imports from `/media/downloads` into `/media/tv|movies` are instant hardlinks,
not copies.

## GPU transcoding

Caliban's containerd uses the nvidia runtime as *default*, so Plex gets NVENC
via `NVIDIA_VISIBLE_DEVICES=all` without claiming the `nvidia.com/gpu` device
plugin resource (which stays free for ML workloads). Enable **Use hardware
acceleration when available** in Plex > Settings > Transcoder.

## First-run wiring (one-time, via each UI)

1. **Plex** (`http://caliban:32400/web` from the LAN, or grab a claim token at
   https://plex.tv/claim first): sign in, add libraries `/media/movies`,
   `/media/tv`, `/media/music`.
2. **qBittorrent**: temporary admin password is in the container log
   (`kubectl logs -n media deploy/qbittorrent`); set a real one, set default
   save path `/media/downloads`.
3. **Prowlarr**: add your indexers; add Sonarr (`http://sonarr:8989`) and
   Radarr (`http://radarr:7878`) under Settings > Apps (API keys from each
   app's Settings > General).
4. **Sonarr/Radarr**: add root folder `/media/tv` / `/media/movies`; add
   qBittorrent as download client (`qbittorrent`, port `8080`).
5. **Overseerr**: sign in with Plex, point at Plex + Sonarr/Radarr.
6. **Tautulli**: point at Plex — use caliban's LAN IP:32400 (Plex is
   hostNetwork, so `plex.media.svc` does not exist).

In-cluster names work because everything shares the `media` namespace.

## Game mode / media mode

`scripts/game-mode.sh` stops the k3s agent + workloads on caliban and shuts
down the cluster VMs, freeing GPU/RAM for gaming. `scripts/media-mode.sh`
brings it all back; ArgoCD re-reconciles this stack automatically. One-time
setup: `sudo scripts/install-mode-switch.sh`.
