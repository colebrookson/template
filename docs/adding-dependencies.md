## Adding dependencies to this project
### AUTHOR: Cole Brookson

`DESCRIPTION` is the single source of truth for all R package dependencies.
The container is built from it — so anything not in `DESCRIPTION` is not
guaranteed to be present in the reproducible environment.

### Adding an R package

1. **Work on a development branch.** No code development on `main`.

2. **Trial the package in your current session** without committing to it yet:
   ```r
   pak::pkg_install("newpackage")
   ```
   This installs into the running container session only — it does not persist
   after the container is rebuilt.

3. **Once you're happy**, add the package to the `Imports:` field in `DESCRIPTION`:
   ```
   Imports:
       dplyr,
       newpackage
   ```

4. **Rebuild the container** via the VS Code command palette:
   `Dev Containers: Rebuild Container`

5. **Test** that the new package loads cleanly and everything still works.

### Adding a system dependency

If the new R package requires a system library (e.g. `libgdal-dev` for `sf`),
add the relevant `apt-get install` line to `sys_deps/sys_deps.sh` before
rebuilding. The comments in that file list the most common ones.
