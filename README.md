
CEPH BUILD ENVIRONMENT - USING DOCKER FOR CONTAINERIZING RELEASE BUILDS
=======================================================================

## ABSTRACT

As Ceph releases are launched, they may eventually only compile on newer
releases of distributions - typically due to availability of packages, their
versions, and even the existence / support of things like python2 vs python3.

We thus require a simple enough environment on which to build Ceph releases,
such that it doesn't take a ludicrous amount of time to set up the
environment, to compile a given release, and to develop on it - may it be for
backport purposes, or hot fixes, or even to track down possible regressions.

Even though the above is the original motivation, we can also leverage this
environment to automate builds and checks, not only for release branches but
for development branches as well. Possibly, this could even be used to
generate RPMs, or the likes.


## ARCHITECTURE

The trickiest part, which we've been messing about quite a lot, is how to keep
this as simple as possible, yet as powerful as possible as well.

Well, the conclusion so far is that, however powerful you may want it to be,
the reality is that we're basically always using it for the same use case:
compiling the code and running a vstart cluster, by attaching a session to a
running container.

As such, if we look into the problem itself (i.e., having a simple way to
compile code, in the fastest way possible, as many times as we need), we reach
a simple solution:

  * we need to know where the source code is;
  * we need ccache;
  * ccache needs to be release specific;
  * we need to automate the build so we press a button without babysitting it;
  * we need to run tests on the compiled code;
  * we need to run an interactive shell on the compiled code.

So far, we've been very relaxed, allowing the user to pretty much specify
whatever they want, however they want, wherever they want - code, ccache,
whatever you think of, we've probably have been allowing it to be specified.

However, we are now taking a simpler approach.

We will have two types of containers images:

  1. base images
  2. whatever else

A base is the critical part, and will be a combination of

  * a base distribution
  * a container image prepared for a given Ceph release

On top of a base image we will then have the build container images. As is, we
are going to focus on building from a git repository; whatever else that may
come after, comes after, and we'll not care about it right now (future
expansions, if any, shall be documented somewhere else - not here).

A _git build image_ will drink from a base image, and will call a build script
as its entrypoint.

A _run image_ will drink from a base image (matching its build image), and
will call _/bin/bash_ as its command.

Both of these images will need to follow, strictly, the same pattern for
host/container volumes. We are not allowing any more customization because
that will just make our lives harder.

The host will be expected to have a **_/ceph_** directory, which will need to
contain:

  * /ceph/ccache - ccache directory, for builds
  * /ceph/src    - containing the source repositories, per release
  * /ceph/bin    - binaries required by the images
  * /ceph/tools  - this project's tools for creating/managing images, etc.

Both the _ccache_ and the _src_ directories will have release-specific
directories underneath. E.g., _/ceph/ccache/luminous_ and
_/ceph/src/luminous_.

These will not be optional, nor customizable.

It will be the build script's responsibility to use these as it pleases. Our
provided script (available in _tools/_) will assume the base images will
already have a _/ceph_ directory created, and shall take the host's _/ceph_ to
be mounted as a volume on the container's _/ceph_. We're not making matters
more complicated than that - if you do wish to make this process more
convoluted, you are welcome.


## How it works

Within _tools/_ you will be able to find the `ceph-build-env` binary. This
will serve most of your purposes.


### Prepare the host system

By running `ceph-build-env prepare`, we will make sure we create the necessary
directory structure in **/ceph**; additionally, we will create two symlinks,
one for _/ceph/tools_ pointing to our _tools/_ directory, and another for
_/ceph/bin_ pointing to our _bin/_ directory. If you, the user, wishes to have
the sources, ccache, and all of that somewhere else other than your root
(which we really understand; so do we, really), then you can run
`ceph-build-env prepare /path/to/cephdir`, and the script will ensure _/ceph_
is a symlink to _/path/to/cephdir_ instead.

We will not make any assumptions about the contents of the _src/_ directory,
nor about ccache. The prepare step is not concerned about the build at all.


### Base Images

We require images we can use for building the code, and, as discussed
previously, these will be a combination of distribution and Ceph release.

If one looks under `images/base`, one will find two directories: `distros` and
`release`. These will form the various available combinations for base images.
However, while one will find actual distribution versions' directories beneath
`distros/`, one will simply find a _Dockerfile_ under `release/`. This is
simply because we don't actually track which releases are available - we don't
know, we don't care; we are trying to beat the odds of time as much as
possible, and presuming to know which releases exist is going to add
complexity at this point. Instead, the release image will be generated by
provinding the release information when building.

To make things easier, `ceph-build-env list-distros` will show the available
distributions; whereas `ceph-build-dev image-build <release> <distro>` will
build an image for a given release on the provided distro. Alternatively, if
one is feeling greedy, `ceph-build-dev image-build-all <release>` will build
images for all the available distributions.

In docker, `docker images` will show the base images as being in the 
_ceph-build-env/base_ repository, with individual images marked with different
tags; e.g., _leap-42.3_ for the distribution image, and _leap-42.3-luminous_
for the release-specific image.

### Building

At the moment of writing, we only support building with **git**. Setting up a
build is simplified by running
`ceph-dev-env build-prepare <distro> <release> [branch]` which will perform
the following steps:

  1. check if _/ceph/src/<distro>-<release>_ exists and is a git repository;
  2. if not, `https://github.com/ceph/ceph.git` will be cloned to
  _/ceph/src/<distro>-<release>_, and the branch _<release>_ will be checked
  out;
  2. if _branch_ has been provided, the branch will be checked out;
  3. check if _/ceph/ccache/<distro>-<release>_ exists, and, if not, create a
  ccache in that directory (by default, we will create a 50GB ccache);
  4. create a git build image for this release.

It is important to mention that if a release repository is found and a branch
is not specified, we will not care about which branch is checked out. This
might mean that, should a different release be checked out, the release's
ccache will be tainted.

Once the build is prepared, and assuming no errors were detected, then running
`ceph-build-env build <distro> <release>` can be called to start building the
repository. The compilation will happen in situ. We could have decided to
build in a different directory (e.g., _/ceph/builds_), but we have been bit by
that in earlier attempts. In hopes of simplifying the process, we're scrapping
that approach. We may backtrack on that decision at a later time, at which
time this statement will be revisited.

Building the repository will fire up the git build image that was prepared in
the previous step (or any previously existing image), and it will be a matter
of waiting for the build to finish. This is the trickiest part, given a build
may fail and, at this moment, we don't have a way of warning about that -
those checks will need to be manual.

### Running an interactive container

To interactively use the build, one simply has to run `ceph-build-env
interactive <distro> <release>`. We could use the release base image, but as a
release or branch are modified, new dependencies may be added. As such, we
will need to create a new image, if not present yet, to effectively run the
build for a release. This image (on repository _ceph-build-env/run_, tag
_<distro>-<release>_) will run a command from our own set of binaries, named
_interactive.sh_. We're going with a custom script instead of `/bin/bash`
because we want to run `install-deps.sh` before we actually run the
interactive shell.



