#!/usr/bin/env bash
# Manage a per-project ESP32 Rust build container.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
ESP_RUST="${ESP_RUST:-1.97.0.0}"
IMAGE="${ESP_IMAGE:-esp32-rs:${ESP_RUST}}"
CARGO_CACHE="${ESP_CARGO_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/esp-cargo}"

if command -v podman >/dev/null 2>&1; then ENGINE=podman
elif command -v docker >/dev/null 2>&1; then ENGINE=docker
else echo "error: neither podman nor docker found" >&2; exit 1; fi

# Project = superproject if we're inside the submodule, else the repo top-level, else $PWD.
# Override with ESP_PROJECT_DIR.
find_project() {
  local d="${ESP_PROJECT_DIR:-}"
  [[ -n "$d" ]] || d="${SCRIPT_DIR}/.."
  printf '%s' "$d"
}
PROJECT_DIR="$(find_project)"
base="$(basename "$PROJECT_DIR")"; base="${base//[^a-zA-Z0-9_.-]/-}"
NAME="esp-${base}-$(printf '%s' "$PROJECT_DIR" | cksum | cut -d' ' -f1)"

exists()  { "$ENGINE" container inspect "$NAME" >/dev/null 2>&1; }
running() { [[ "$("$ENGINE" container inspect -f '{{.State.Running}}' "$NAME" 2>/dev/null)" == "true" ]]; }

cmd_build() {
  "$ENGINE" build "$@" \
    --build-arg ESP_RUST="$ESP_RUST" \
    --build-arg USERNAME="${ESP_USER:-$(id -un)}" \
    --build-arg USER_UID="$(id -u)" \
    --build-arg USER_GID="$(id -g)" \
    -t "$IMAGE" -f "$SCRIPT_DIR/Containerfile" "$SCRIPT_DIR"
}

ensure_image() {
  "$ENGINE" image inspect "$IMAGE" >/dev/null 2>&1 || cmd_build
}

cmd_up() {
  ensure_image
  if exists; then
    local have want
    have="$("$ENGINE" container inspect -f '{{.Image}}' "$NAME")"
    want="$("$ENGINE" image inspect -f '{{.Id}}' "$IMAGE")"
    [[ "$have" == "$want" ]] || echo "warning: container uses an older image; run '$0 rm' to recreate it" >&2
    running || "$ENGINE" start "$NAME" >/dev/null
    return
  fi
  local user_args=()
  if [[ "$ENGINE" == podman ]]; then user_args=(--userns=keep-id)
  else user_args=(--user "$(id -u):$(id -g)"); fi
  mkdir -p "$CARGO_CACHE"
  "$ENGINE" run -d --name "$NAME" --stop-timeout 2 "${user_args[@]}" \
    -e HOME=/tmp -e CARGO_HOME=/cache/cargo \
    -v "$CARGO_CACHE":/cache/cargo:Z \
    -v "$PROJECT_DIR":"$PROJECT_DIR":Z -w "$PROJECT_DIR" \
    "$IMAGE" sleep infinity >/dev/null
  echo "started $NAME (project: $PROJECT_DIR)" >&2
}

exec_in() {
  local tty=(-i); [[ -t 0 && -t 1 ]] && tty=(-it)
  "$ENGINE" exec "${tty[@]}" "$NAME" /usr/local/bin/esp-env "$@"
}

cmd_status() {
  echo "project:   $PROJECT_DIR"
  echo "container: $NAME"
  echo "image:     $IMAGE"
  if running; then echo "state:     running"
  elif exists; then echo "state:     stopped"
  else echo "state:     not created"; fi
}

usage() {
  cat <<EOF
Usage: $0 [command]

  (none) | shell   start the container if needed and open a shell in the project root
  exec CMD...      run a command inside the container, e.g.  $0 exec cargo build --release
  build [ARGS]     (re)build the image (e.g. --no-cache); ESP_RUST=<ver> selects the toolchain
  up               create/start the container without attaching
  stop             stop the container
  rm               stop and remove the container
  rmi              remove the image
  status           show project, container and state

Env: ESP_RUST ($ESP_RUST)  ESP_IMAGE  ESP_CARGO_CACHE  ESP_PROJECT_DIR
EOF
}

case "${1:-shell}" in
  shell)  cmd_up; exec_in bash ;;
  exec)   shift; [[ $# -gt 0 ]] || { usage; exit 1; }; cmd_up; exec_in "$@" ;;
  build)  shift; cmd_build "$@" ;;
  up)     cmd_up ;;
  stop)   exists && "$ENGINE" stop "$NAME" >/dev/null && echo "stopped $NAME" || echo "not created" ;;
  rm)     exists && "$ENGINE" rm -f "$NAME" >/dev/null && echo "removed $NAME" || echo "not created" ;;
  rmi)    "$ENGINE" rmi "$IMAGE" ;;
  status) cmd_status ;;
  -h|--help|help) usage ;;
  *) usage; exit 1 ;;
esac
