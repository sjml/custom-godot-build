Cross-compiling Godot is a big pain, but I want an easy way to have export templates that incorporate certain changes. (At the time of this writing, a pull request.)

I wasted a bunch of time trying to set up local build environments, VMs, etc. Then I figured "just let GitHub Actions do it; they have a bunch of different build environments all ready to go." 

[So the magic all lives in the workflow.](./.github/workflows/build.yml)

## Caveats
* These are not (at the moment) general "usable for everyone" templates, but do what I need them to do for *my* project. But if I get motivated I could see myself making them more configurable. Maybe.
* macOS builds are not signed; I'm just removing the quarantine flag after I download in my project, but whenever I pay for an Apple dev account again, I'll add proper signing here.
  * They also need to have permissions fixed; I could fix that here, but it's kind of a pain and I'm scripting removal of the quarantine flag anyway, so easy to fix on the download end.
* Doesn't do Windows build because I currently have no way of testing them.

