# Asset Ledger

Verify that files still match a release manifest. Useful when bundling fonts, textures, sample data, icons, and other non-code files for a release.

```sh
python asset_ledger.py examples/assets.json
python -m unittest -v
```

Each asset declares a relative forward-slash `path`, lowercase `sha256`, `origin`, and `license`. Records whose origin is anything other than `original` also need a nonempty local `notice` file. Use `--root` to supply a different release directory.

The audit catches edited or missing assets, duplicated entries (including case collisions), missing notices, and paths that resolve outside the release directory. Exit status 0 means every declared entry passed, 1 means there are findings, and 2 means the manifest could not be read.

Ledger entries describe the publisher's provenance claims. A passing audit verifies bytes and declared notice files. Human review is still needed to determine if a license covers the intended distribution and to detect undeclared assets.
