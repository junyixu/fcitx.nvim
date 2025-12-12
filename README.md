# fcitx.nvim

fcitx.nvim keeps Neovim and fcitx5 in sync through direct DBus calls. Talking to the controller over DBus is noticeably faster and more reliable than shelling out to fcitx5-remote, so the input method switches immediately whenever you leave or enter insert mode.

## Requirements

- A working fcitx5 session on the same user bus.
- ldbus (Lua DBus binding).

<details><summary>Arch Linux dependency installation</summary>

Install the Lua 5.1 binding packaged by Arch first:

```bash
yay -S lua51-ldbus
```

ldbus links straight against the system DBus headers, keeping this plugin entirely in Lua with no Python or shell helpers.

</details>

<details><summary>NixOS dependency installation</summary>

On NixOS, you can wrap Neovim with a Lua 5.1/LuaJIT environment that includes `ldbus`:

```nix
programs = {
  neovim = {
    enable = true;
    package = (
      pkgs.symlinkJoin {
        inherit (pkgs.neovim-unwrapped) meta lua;
        name = "neovim-with-lua";
        paths = [ pkgs.neovim-unwrapped ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        version = lib.getVersion pkgs.neovim-unwrapped;
        postBuild =
          let
            luaEnv = pkgs.luajit.withPackages (
              ps: with ps; [
                ldbus
              ]
            );
          in
          ''
            rm $out/bin/nvim
            makeWrapper ${pkgs.neovim-unwrapped}/bin/nvim $out/bin/nvim \
              --set LUA_PATH '${luaEnv}/share/lua/5.1/?.lua;${luaEnv}/share/lua/5.1/?/init.lua;;' \
              --set LUA_CPATH '${luaEnv}/lib/lua/5.1/?.so;;'
          '';
      }
    );
  };
};
```

</details>

## Installation

### lazy.nvim

```lua
{
  "junyixu/fcitx.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("fcitx").setup({
      -- enable_cmdline = true, -- also toggle when entering / or ?
    })
  end,
}
```

Set `vim.g.fcitx_nvim_disable_auto_setup = true` before loading the plugin if you want to call `require('fcitx').setup()` manually.

## Usage

By default the plugin installs autocmds that:

- switch to ASCII when leaving insert mode
- remember the per-buffer state
- restore the input method when re-entering insert mode

Enable command-line toggling via `enable_cmdline = true` if you need `/` or `?` searches to reuse the previous IME. Low-level helpers remain exposed under `require('fcitx').dbus`.

## Alternative

- https://github.com/lilydjwg/fcitx.vim
- https://github.com/alohaia/fcitx.nvim
- https://github.com/h-hg/fcitx.nvim
