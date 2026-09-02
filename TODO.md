# Dotfiles Customization TODO

The following packages are installed on your system and *can* have configuration files, but you don't currently have them configured. 

If you decide to customize them in the future, create the following files inside your dotfiles repository (the `~/.dotfiles/` folder) so that `stow` can automatically link them to the correct locations on your system!

## Missing Configurations

- [ ] **bat**
  - **Repo Path:** `bat/.config/bat/config`
  - **System Target:** `~/.config/bat/config`
  
- [ ] **npm**
  - **Repo Path:** `npm/.npmrc`
  - **System Target:** `~/.npmrc`

- [ ] **picom** (Compositor)
  - **Repo Path:** `picom/.config/picom/picom.conf`
  - **System Target:** `~/.config/picom/picom.conf`

- [ ] **stow**
  - **Repo Path:** `stow/.stowrc`
  - **System Target:** `~/.stowrc`

- [ ] **xinit** (Xorg initialization)
  - **Repo Path:** `xinit/.xinitrc`
  - **System Target:** `~/.xinitrc`

- [ ] **bc** (Calculator)
  - **Repo Path:** `bc/.bcrc`
  - **System Target:** `~/.bcrc`

*(Note: polybar and sxhkd configurations are handled internally by your gh0stzk bspwm package, so they are omitted from this list to prevent conflicts!)*
