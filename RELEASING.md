# Releasing Happening

Public repository: [TechLuddite/Happening](https://github.com/TechLuddite/Happening). Mod-site owners: [TechLuddite on ModWorkshop](https://modworkshop.net/user/techluddite) and [TechLuddite on VostokMods](https://vostokmods.net/user/techluddite).

The GitHub repository is public. Live listings: [ModWorkshop 59405](https://modworkshop.net/mod/59405) and [Vostok Mods `happening`](https://vostokmods.net/mod/happening). Building and running this repository's packaging checks need only Python's standard library.

## Build the release files

Run from the repository root:

```sh
python3 -m unittest discover -s tests -p 'test_*.py'
python3 scripts/pack.py
python3 scripts/pack.py --release-notes
```

Upload `dist/Happening.vmz`. GitHub also receives `dist/Happening.vmz.sha256`. From `dist/`, `sha256sum --check Happening.vmz.sha256` verifies the archive. Use the same `.vmz` for all three hosts so its checksum and runtime stay identical.

The archive explicitly includes only `mod.txt`, `Happening_LICENSE`, and the three scripts under `mods/Happening/`. The license has a mod-specific archive name so it does not mount over a shared `res://LICENSE` path. Documentation, listing text, artwork, scripts, and packaging tests remain in the source repository.

## GitHub releases

The repository uses branch `main` and origin `https://github.com/TechLuddite/Happening.git`. For a new release, update the version in `mod.txt`, add the matching changelog section, and merge the reviewed changes to `main`.

**A push to `main` automatically publishes `v<version>` when that version has no existing GitHub release and the workflow succeeds.** The workflow runs the standalone tests, builds the archive and checksum, verifies the downloaded artifact, and takes release notes from the matching changelog section. The release job has `contents: write`; pull requests only test/build. The workflow uses GitHub's [documented release permission](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax).

An existing release is preserved. An existing tag pointing to a different commit causes the release job to fail rather than move that tag. An API failure is not treated as an absent release. Manual workflow dispatch on `main` can retry publication after an operational failure.

Download the resulting release asset and check its checksum before using it for the site submissions. The GitHub source archives are not the mod download.

## Mod sites

After each GitHub release, update both listings by hand with the release's `Happening.vmz`:

1. ModWorkshop [59405](https://modworkshop.net/mod/59405): upload the file with its version and label, then paste the short description and description from [distribution/modworkshop.md](distribution/modworkshop.md).
2. Vostok Mods [`happening`](https://vostokmods.net/mod/happening): add the version with the same file and tested game versions, then paste the summary and description from [distribution/vostokmods.md](distribution/vostokmods.md). Keep the AI assistance disclosure enabled, consistent with the site's [content rules](https://vostokmods.net/legal/rules).

Neither site accepts API uploads: ModWorkshop's API rules allow GET requests only, and Vostok Mods has no documented write API.

## Update feed and later versions

Since 0.1.2 the manifest names ModWorkshop as Metro's update feed:

```ini
[updates]
source="modworkshop:59405"
```

Vostok Mods rewrites this line in its uploaded copy to `source="vostokmods:<mod id>"`, so its file differs from the GitHub asset in that line only.

For each later release, update `mod.txt` and add its matching `## X.Y.Z` changelog section. Keep development and maintained-release manifest/runtime copies identical. Validate gameplay changes against the current game in the development workspace; this repository's standalone tests validate distribution, not gameplay. Merge the tested version to `main` to publish its GitHub release, then update both mod-site downloads with that same asset. Do not alter assets or retag a version that is already released.
