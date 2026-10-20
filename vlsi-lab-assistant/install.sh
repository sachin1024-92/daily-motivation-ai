#!/usr/bin/env bash
# Installs vlab for the current user (no root needed):
#   ~/.local/share/vlab   program files
#   ~/.local/bin/vlab     command
# then runs the interactive `vlab setup`.
#
#   ./install.sh            install + setup
#   ./install.sh --no-setup install only
set -e

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${VLAB_INSTALL_DIR:-$HOME/.local/share/vlab}"
BIN="$HOME/.local/bin"

echo ":: installing vlab from $SRC to $DEST"
mkdir -p "$DEST" "$BIN"
if [ "$SRC" != "$DEST" ]; then
  rm -rf "$DEST.new"
  mkdir -p "$DEST.new"
  cp -r "$SRC/bin" "$SRC/libexec" "$SRC/claude" "$SRC/templates" "$SRC/config" "$SRC/README.md" "$DEST.new/"
  rm -rf "$DEST"
  mv "$DEST.new" "$DEST"
fi
chmod +x "$DEST/bin/vlab" "$DEST/libexec/"*.py
ln -sf "$DEST/bin/vlab" "$BIN/vlab"
echo "   linked $BIN/vlab"

# Make sure ~/.local/bin is on PATH for bash and for tcsh/csh (common in EDA labs).
add_line() { # file line
  [ -f "$1" ] && grep -qF "$2" "$1" && return 0
  printf '\n# added by vlab installer\n%s\n' "$2" >>"$1"
  echo "   updated $1"
}
case ":$PATH:" in
  *":$BIN:"*) ;;
  *)
    add_line "$HOME/.bashrc" 'export PATH="$HOME/.local/bin:$PATH"'
    if [ -f "$HOME/.cshrc" ] || [ -f "$HOME/.tcshrc" ] || [[ "${SHELL:-}" == *csh ]]; then
      f="$HOME/.cshrc"; [ -f "$HOME/.tcshrc" ] && f="$HOME/.tcshrc"
      add_line "$f" 'setenv PATH "$HOME/.local/bin:$PATH"'
    fi
    export PATH="$BIN:$PATH"
    echo "   open a new terminal (or run: export PATH=\"\$HOME/.local/bin:\$PATH\") to use 'vlab'"
    ;;
esac

# Refresh workspace copies of the Claude instructions/skills when upgrading.
if [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/vlab/vlab.conf" ] && [ "${1:-}" != "--fresh" ]; then
  echo ":: existing config found - refreshing Claude files in your workspace"
  bash -c '. "$1"; mkdir -p "$VLAB_WORKSPACE/.claude/skills"
           for s in "$2"/claude/skills/*/; do rm -rf "$VLAB_WORKSPACE/.claude/skills/$(basename "$s")"; cp -r "$s" "$VLAB_WORKSPACE/.claude/skills/"; done
           if [ ! -f "$VLAB_WORKSPACE/CLAUDE.md" ] || grep -qs vlab-managed "$VLAB_WORKSPACE/CLAUDE.md"; then cp "$2/claude/CLAUDE.md" "$VLAB_WORKSPACE/CLAUDE.md"; fi
           [ -f "$VLAB_WORKSPACE/.claude/settings.json" ] || cp "$2/claude/settings.json" "$VLAB_WORKSPACE/.claude/settings.json"
           [ -e "$VLAB_WORKSPACE/templates" ] || ln -s "$2/templates" "$VLAB_WORKSPACE/templates"' \
    _ "${XDG_CONFIG_HOME:-$HOME/.config}/vlab/vlab.conf" "$DEST" || true
  echo ":: done. Run 'vlab doctor' to check everything."
  exit 0
fi

if [ "${1:-}" != "--no-setup" ]; then
  echo
  "$BIN/vlab" setup
fi
