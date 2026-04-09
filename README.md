# typst-ling

Personal Neovim tooling for linguistics-focused Typst workflows. This is a public repo, but the plugin isn't yet meant for public use. It _should_ work, but this is mostly a very simple personal plugin that makes sense in my own workflow. Feel free to use/fork it, of course.

## Install

You can install this like any other Neovim plugin. No extra config is required just to get the commands:

```lua
{
  "guilhermegarcia/typst-ling",
}
```

If you want keymaps, here is a minimal example:

```lua
{
  "guilhermegarcia/typst-ling",
  keys = {
    { "<leader>lf", "<cmd>TypstLingFunctions<cr>", desc = "Typst-Ling functions" },
    { "<leader>lt", "<cmd>TypstLingTreeIndent<cr>", desc = "Typst-Ling tree indent" },
  },
}
```

If you want source jumping for local checkouts of `phonokit` or `synkit`, add `setup()` with the package roots:

```lua
{
  "guilhermegarcia/typst-ling",
  config = function()
    require("typst-ling").setup({
      phonokit_root = "/path/to/phonokit",
      synkit_root = "/path/to/synkit",
    })
  end,
}
```

Or combine both:

```lua
{
  "guilhermegarcia/typst-ling",
  keys = {
    { "<leader>lf", "<cmd>TypstLingFunctions<cr>", desc = "Typst-Ling functions" },
    { "<leader>lt", "<cmd>TypstLingTreeIndent<cr>", desc = "Typst-Ling tree indent" },
  },
  config = function()
    require("typst-ling").setup({
      phonokit_root = "/path/to/phonokit",
      synkit_root = "/path/to/synkit",
    })
  end,
}
```

Current `v1` features:

- package-aware function picker for `phonokit` and `synkit`. This is especially useful if you're not too familiar with these packages and want to check if a given function exists.
- `#tree()` reindent command for `synkit`. Strings aren't auto-indented by Tinymist, so you need to manually break lines if you want your tree specification to be a bit more structured/readable. This function fixes that by auto-indenting the tree string passed to `#tree()`.
