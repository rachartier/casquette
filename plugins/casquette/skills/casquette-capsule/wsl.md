# GUI apps on WSL2

Mount `/tmp/.X11-unix:/tmp/.X11-unix` in `[volumes]`. With WSLg, set `DISPLAY = ":0"`, `WAYLAND_DISPLAY = "wayland-0"` and `XDG_RUNTIME_DIR = "/mnt/wslg/runtime-dir"` in `[env]`; with an external X server (VcXsrv, X410), set `DISPLAY = "$DISPLAY"`.
