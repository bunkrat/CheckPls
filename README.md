# Check, Pls!

A Neovim plugin to toggle markdown checkboxes.

It supports the following:

- individual checkbox
- multi checkbox (viaul mode)
- toggle tree (by calling on parent)

```
- [x] Parent Task
  - [ ] Child Task
  - [x] Child Task
    - [x] Subchild Task
    - [ ] Subchild Task
- [x] Parent Task       <-- tree toggled
  - [x] Child Task
  - [x] Child Task
```

## Setup

with Lazy:

```lua
return {
  'bunkrat',

  opts = {}
}
```

The default keybindings are:

```
cursor = '<leader>tt',
parent = '<leader>tp',
```

The `cursor` keybind is used for both individual checkboxes and multi (visual
select) checkboxes.

To change the keybinds,

```lua
return {
  'bunkrat',

  opts = {
      mappings = { -- optionally remap keybinds
          cursor = '<leader>kj',
          parent = '<leader>tn'
      }
  }
}
```
