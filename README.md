# master-config

My bunch of dotfiles all in one place.

```bash
git clone <your-repo-url> ~/master-config
cd ~/master-config
chmod +x install.sh
./install.sh
exec fish
```

## Overview

- `Neovim` text editor.
- `Starship` prompt formatter.
- `Tmux` multiplexer.
- `Fish` shell.
- `Alacritty` terminal emulator.
- Lots of executable utilities.
- More!

## Context

In Sophomore year, I got very interested in NixOS. I love setting up systems, but it gets tiresome when you repeat the same motions over and over again. I was so excited at the idea of a system design that I could port to go with me. It was the same idea that drew me to Ansible as a freshman. I spent hours configuring instead of doing my homework, and ran into limitations (likely for lack of understanding) and let it go.

Fast forward to senior year and my laptop is dying. I sat envisioning my next laptop and how I would set up Linux to be just amazing on it. Excited but trying to keep my current laptop running on, I realized most of what I want to set up can be made repeatable!

It's mostly terminal stuff, but I hope to make it highly flexible in the OS used and the targeted use.
