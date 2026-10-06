# Releasing Happening

Public repository target: `TechLuddite/Happening`. Mod-site owners: [TechLuddite on ModWorkshop](https://modworkshop.net/user/techluddite) and [TechLuddite on VostokMods](https://vostokmods.net/user/techluddite).

This source tree is prepared for first publication. The GitHub repository and Happening listings have not been created by this preparation. Version 0.1.0 uses the runtime already tested by the player. Building and running this repository's packaging checks need only Python's standard library.

## Build the release files

Run from the repository root:

```sh
python3 -m unittest discover -s tests -p 'test_*.py'
python3 scripts/pack.py
python3 scripts/pack.py --release-notes
```

Upload `dist/Happening.vmz`. GitHub also receives `dist/Happening.vmz.sha256`. From `dist/`, `sha256sum --check Happening.vmz.sha256` verifies the archive. Use the same `.vmz` for all three hosts so its checksum and runtime stay identical.

The archive explicitly includes only `mod.txt`, `Happening_LICENSE`, and the three scripts under `mods/Happening/`. The license has a mod-specific archive name so it does not mount over a shared `res://LICENSE` path. Documentation, listing text, artwork, scripts, and packaging tests remain in the source repository.

## First GitHub publication

The prepared local repository uses branch `main` and origin `https://github.com/TechLuddite/Happening.git`. Inspect the files and initial commit before pushing. Authenticate with `gh auth status`, then create the empty public repository and push:

```sh
gh repo create TechLuddite/Happening --public \
  --description "An event on every shelter exit in Road to Vostok."
git push -u origin main
```

**The first push to `main` automatically publishes GitHub release `v0.1.0`.** The workflow runs the standalone tests, builds the archive and checksum, verifies the downloaded artifact, and takes release notes from the matching changelog section. The release job has `contents: write`; pull requests only test/build. The prepared workflow uses GitHub's [documented release permission](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax).

An existing release is preserved. An existing tag pointing to a different commit causes the release job to fail rather than move that tag. An API failure is not treated as an absent release. Manual workflow dispatch on `main` can retry publication after an operational failure.

Download the resulting release asset and check its checksum before using it for the site submissions. The GitHub source archives are not the mod download.

## ModWorkshop

1. Sign in as TechLuddite and open [Upload Mod](https://modworkshop.net/upload).
2. Use [distribution/modworkshop.md](distribution/modworkshop.md) for listing fields and description. Road to Vostok is game 864; the existing Fixes/Tweaks category is 932.
3. Upload `Happening.vmz`, set version 0.1.0, and link the public GitHub source repository. Add `artwork/cover.png` and optional gameplay screenshots.
4. Review the listing, publish it, and record the actual mod URL/ID. Add the VostokMods link after that listing exists.

## VostokMods

1. Sign in as TechLuddite and open [New mod](https://vostokmods.net/new/mod).
2. Use [distribution/vostokmods.md](distribution/vostokmods.md) for the name, summary, license, and AI disclosure. Request slug `happening` if available and create the mod page.
3. In the new page's settings, add the description, dependency, tested game version, and version 0.1.0 with the same `Happening.vmz`. Add `artwork/cover.png`, source link, version notes, and the actual ModWorkshop URL.
4. Keep the AI assistance disclosure enabled for code/documentation, consistent with the project's credits and the site's [content rules](https://vostokmods.net/legal/rules). Review the listing before publication and record its actual slug/URL.

Both site descriptions are prepared, but categories, tags, and supported-game-version choices should use the options present in their live forms. No listing IDs or URLs have been fabricated.

## Update feed and later versions

The 0.1.0 manifest deliberately has no `[updates]` source because the listings do not exist yet. After publication, choose one live listing as Metro's canonical update feed and add its actual identity in the next version:

```ini
[updates]
source="modworkshop:ACTUAL_MOD_ID"
```

Or use `source="vostokmods:ACTUAL_PUBLISHED_SLUG"`. These are examples to fill with real published values, not entries to ship verbatim.

For each later release, update `mod.txt` and add its matching `## X.Y.Z` changelog section. Keep development and maintained-release manifest/runtime copies identical. Validate gameplay changes against the current game in the development workspace; this repository's standalone tests validate distribution, not gameplay. Merge the tested version to `main` to publish its GitHub release, then update both mod-site downloads with that same asset. Do not alter assets or retag a version that is already released.
