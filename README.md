# typst-ling

Personal Neovim tooling for linguistics-focused Typst workflows. This is a public repo, but the plugin isn't yet meant for public use. It _should_ work, but this is mostly a personal plugin that makes sense in my own workflow. Feel free to use/fork it, of course.

Current `v1` features:

- package-aware function picker for `phonokit` and `synkit`. This is especially useful if you're not too familiar with these packages and want to check if a given function exists.
- `#tree()` reindent command for `synkit`. Strings aren't auto-indented by Tinymist, so you need to manually break lines if you want your tree specification to be a bit more structured/readable. This function fixes that by auto-indenting the tree string passed to `#tree()`.
