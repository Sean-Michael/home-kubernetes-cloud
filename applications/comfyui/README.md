# comfyui

ComfyUI on the RTX 2070 Super, preloaded with **MiniMax H3** — the Hailuo video
model MiniMax open-sourced on 2026-08-03 with day-0 native ComfyUI support
(text→video, image→video, with stereo audio in the same pass).

| What | Where |
|---|---|
| Web UI (tailnet) | https://comfyui.tail4dd976.ts.net |
| Web UI (LAN fallback) | http://caliban:30188 |
| App state | `/data/appdata/comfyui` (ComfyUI checkout, custom nodes, outputs under `ComfyUI/output`) |
| Models | `/data/models/comfyui/{diffusion_models,text_encoders,vae,checkpoints,loras,...}` |

## How it fits on 8 GB of VRAM

H3 is a 33B-param model; the full weights are way beyond this card. We use the
Comfy-Org quantized repack (`int8 convrot` diffusion model + `NVFP4 AWQ`
Qwen3-VL text encoder, ~40 GB on disk) and lean on ComfyUI's dynamic VRAM /
block-swap, which streams weights from system RAM (caliban has 64 G — the
Deployment's 48Gi memory limit is load-bearing). Expect it to *work*, not to be
fast: minutes per short clip. Sage Attention (the usual 2× speedup) needs
Ampere or newer, so it's not available on Turing. If generation OOMs, add
`--disable-pinned-memory` (or as a bigger hammer `--novram`) to `CLI_ARGS` in
`manifests/comfyui.yaml`.

Classic SD checkpoints (SDXL, SD1.5, Flux-schnell GGUF, …) drop into
`/data/models/comfyui/checkpoints` / `diffusion_models` and run comfortably on
this card — the extra-model-paths ConfigMap maps all the standard folders.

## Moving parts

- **`manifests/comfyui.yaml`** — Deployment (`yanwk/comfyui-boot:cu128-slim`,
  copies its bundled ComfyUI into `/root` on first boot), NodePort Service, and
  two ConfigMaps: extra-model-paths (points ComfyUI at `/models` so the
  boot-time copy never collides with a volume inside it) and a `pre-start.sh`
  hook that git-updates the persistent checkout to the latest ComfyUI release
  tag on every pod start — the image's bundled version lags behind what H3
  needs (≥ 0.30.0). To pin ComfyUI, delete the hook from the ConfigMap.
  Claims `nvidia.com/gpu: 1` (ML convention) — mutually exclusive with
  vllm/home-mlops on the single GPU, by design.
- **`manifests/minimax-h3-download-job.yaml`** — one-shot, resumable, idempotent
  ~40 GB pull of the H3 quantized weights from
  [Comfy-Org/MiniMax-H3](https://huggingface.co/Comfy-Org/MiniMax-H3). The 21 G
  reference-to-video checkpoint is skipped; add a `fetch` line if you want R2V.
- **`manifests/routes.yaml`** — HTTPRoute on the shared `caliban-gateway`.

## First run

1. ArgoCD syncs everything; the download Job and ComfyUI's first-boot clone run
   in parallel (~10 min boot, download depends on WAN speed).
2. Open the UI → *Workflow → Browse Templates → Video* → pick a **MiniMax H3**
   template (T2V or I2V). The model files are already in place, no download
   prompts.
3. Later ComfyUI updates: use ComfyUI-Manager in the UI, or
   `rm -rf /data/appdata/comfyui/ComfyUI` (keeps `/data/models`) and let the
   pod re-clone.

## Caveats

- **License**: the MiniMax H3 community license reportedly carries a territory
  clause excluding the US/EU/UK/KR — fine to know about for a private homelab,
  but read it before building anything on top.
- Game mode (`scripts/game-mode.sh`) stops k3s and frees the GPU; state and
  models are all hostPath under `/data`, so flips are lossless.
