# neotest-catch2
This plugin provides a cpp(Catch2) adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.


[![Demo](./demo.png)](./demo.png)

## Status:

**Work in progress 🚧**.

## Seriously dont use it yet!

## Installation

Using packer:

```lua
use({
  'nvim-neotest/neotest',
  requires = {
    'amar-laksh/neotest-catch2',
  }
  config = function()
    require('neotest').setup({
      ...,
      adapters = {
        require('neotest-catch2'),
      }
    })
  end
})
```
## Note:
Checkout out my config to understand how to set it up: [My config](https://github.com/amar-laksh/neovim-config/blob/main/lua/plugins/nvim-test.lua#L31)

## TODO

- [x] Test cases
- [x] Debugging test cases
- [ ]  Scenarios
- [ ]  Sections
- [ ]  Template test cases

