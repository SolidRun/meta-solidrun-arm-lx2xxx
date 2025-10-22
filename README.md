# SolidRun LX2160A Yocto BSP

## Build Instructions

Start in a **new empty directory** with plenty of free disk space - at least 30GB, Then:

1. download the build recipes:

   ```
   repo init -u https://github.com/nxp-qoriq/yocto-sdk.git -b kirkstone -m ls-5.15.71-2.2.0.xml
   repo sync
   git clone -b kirkstone https://github.com/SolidRun/meta-solidrun-arm-lx2xxx.git sources/meta-solidrun-arm-lx2xxx
   ```

2. apply downstream patches to dependent layers:

   - `poky`: add support for wic images without partition table (for xspi image)

      ```
      pushd sources/poky
      git am ../meta-solidrun-arm-lx2xxx/patches/poky/0001-wic-add-supppport-for-generating-images-without-part.patch
      popd
      ```

3. Initialise a build directory with example configuration files based on lx2160ardb, and appropriate shell environment variables:

       source ./setup-env -m lx2160ardb-rev2 -b build_lx2160a-rev2-honeycomb

4. Adapt example configuration files for SolidRun LX2160A Honeycomb:

   - edit `build_lx2160acex7-rev2/conf/bblayers.conf`:

     Append path to meta-solidrun-arm-lx2xxx:

         BBLAYERS += " <insert-your-workdir>/sources/meta-solidrun-arm-lx2xxx"

   - edit `build_lx2160acex7/conf/local.conf`:

     Set machine to `lx2160a-rev2-honeycomb`:

     ```diff
     -MACHINE ??= 'lx2160ardb-rev2'
     +MACHINE ??= 'lx2160a-rev2-honeycomb'
     ```

   - See below for additional configuration options.

5. Build nxp image `fsl-image-networking`:

       bitbake fsl-image-networking

6. Generate bootable disk image:

   NXP QorIQ Layers by default do not assemble full bootable disk images,
   users are expected to install all components to various offsets manually.

   SolidRun provides [wic](https://docs.yoctoproject.org/dev/dev-manual/wic.html) configuration files for generating bootable disk images from the build artifacts.
   This process can be launched after a successful build:

   - SD-Card / eMMC (includes rootfs):

         wic create -m lx2160a-bootimg-mmc -e fsl-image-networking

     This generates a bootable disk image named `lx2160a-bootimg-mmc.wks-<timestamp>-mmcblk.direct` that is suitable
     for writing to SD-Card or eMMC data partition, from the previously built `fsl-image-networking` target.

   - SPI Flash (without rootfs):

         wic create lx2160a-bootimg-xspi -e fsl-image-networking

     This generates a bootable spi flash image named `lx2160a-bootimg-xspi.wks-<timestamp>-mmcblk.direct` that is suitable
     for writing to SPI flash, from the previously built `fsl-image-networking` target's bootloader parts.

   - SD-Card / eMMC / USB / SATA / NVMe (rootfs only):

         wic create -m lx2160a-rootimg -e fsl-image-networking

     This generates a bootable disk image named `lx2160a-rootimg.wks-<timestamp>-mmcblk.direct` that is suitable
     for writing to any block storage, from the previously built `fsl-image-networking`.
     It comes with kernel + rootfs only, use on separate media, together with an SD or SPI boot image.

Note: The build environment and ability to run `bitbake` is lost when closing the terminal or rebooting.
It can be restored at any time by entering the build directory and sourcing the aut-generated `SOURCE_THIS` file:

```
cd <insert-your-workdir>/build_lx2160acex7-rev2
source SOURCE_THIS
```

## Options

### Supported Machines

This Layer supports the following machines:

| Machine                  | Description                                                                    |
| ------------------------ | ------------------------------------------------------------------------------ |
| lx2160a-clearfog-cx      | LX2160A COM-Express 7 on Clearfog-CX, LX2160A Silicon 1.0 (preview version)    |
| lx2160a-honeycomb        | LX2160A COM-Express 7 on Honeycomb, LX2160A Silicon 1.0 (preview version)      |
| lx2160a-rev2-cex6-evb    | SolidRun-internal Evaluation Board, LX2160A Silicon 2.0 (production version)   |
| lx2160a-rev2-clearfog-cx | LX2160A COM-Express 7 on Clearfog-CX, LX2160A Silicon 2.0 (production version) |
| lx2160a-rev2-honeycomb   | LX2160A COM-Express 7 on Honeycomb, LX2160A Silicon 2.0 (production version)   |
| lx2162a-rev2-clearfog    | LX2162A SoM on Clearfog                                                        |

### Supported Images

This Layer supports the following images:

| Image                     | Description                                                                    |
| ------------------------- | ------------------------------------------------------------------------------ |
| fsl-image-networking      | Typical networking features and basic cli utilities                            |
| fsl-image-networking-full | Demo of all packages tested by NXP including dpdk, dpdk examples and vpp       |

### DDR Clock

DDR Clock can be configured in local.conf using `LX2160A_DDR_SPEED`, supported values are:

- `2400`
- `2600`
- `2666`
- `2900` only for LX2162A, and LX2160A binned 2GHz and higher (default)
- `3200` only for LX2160A binned 2.2GHz

### CPU Clock

CPU (Cortex A72) Clock can be configured in local.conf using `LX2160A_CPU_SPEED`, supported values are:

- `2000` (default, recommended)
- `2200` (for over-clocking, or for specifically purchased 2.2GHz binned SoC)

### Bus Clock

Bus clock can be configured in local.conf using `LX2160A_BUS_SPEED`, supported values are:

- `650`
- `700` only for LX2160A binned 2GHz and higher (default)
- `750` (for over-clocking, or for specifically purchased 2.2GHz binned SoC)

### MC DPC & DPL

Management Complex configuration can be configured in local.conf using `MC_FLAVOUR`, `MC_DPC` and `MC_DPL` variables, supported values are:

- `MC_FLAVOUR=CEX6`:

   - `MC_DPC=evb-s1_3-s2_0-dpc.dtb MC_DPL=evb-s1_3-s2_0-dpl.dtb`

- `MC_FLAVOUR=CEX7`:

   - `MC_DPC=clearfog-cx-s1_8-s2_0-dpc.dtb MC_DPL=clearfog-cx-s1_8-s2_0-dpl.dtb`

Additional configurations are added by patching `mc-utils` package and adding files at `LX2160A-<MC_FLAVOUR>/`.

## Known Issues

## Failed to spawn fakeroot worker: [Errno 32] Broken pipe

On systems with glibc newer than 2.36 builds will fail when either:

- libfakeroot had been built against glibc later than 2.36
- host system glibc is later than 2.36

Yocto uninative package can be updated for glibc-2.40 by cherry-picking a few commits from yocto kirkstone branch into NXPs BSP:

    cd bsp/sources/poky
    git cherry-pick 2890968bbce028efc47a19213f4eff2ccaf7b979
    git cherry-pick bba090696873805e44b1f7b3278ef8369763a176
    git cherry-pick aab6fc20de9473d8d7f277332601cbae70c53320
    git cherry-pick 43b94d2b8496eae6e512c6deb291b5908b7ada47
    git cherry-pick b8fded3df36ab206eaf3bc25b75acda2544679c5
    git cherry-pick b4b545cd9d3905253c398a6a42a9bc13c42073be
    git cherry-pick ad9420b072896b6a58a571c8123bcb17a813a1e7
    git cherry-pick 529c7c30e6a1b7e1e8a5ba5ba70b8f2f2af770ec
    git cherry-pick b36affbe96b2f9063f75e11f64f5a8ead1cb5c55
    git cherry-pick 8190d9c754c9c3a1962123e1e86d99de96c1224c

Cache must also be cleared before the next build can succeed:

    cd bsp/build
    rm -rf tmp ../sstate-cache cache

### permission error in disable_network

Bitbake can fail with a confusing permission error while trying to disable it's child processes network access:

```
ERROR: PermissionError: [Errno 1] Operation not permitted

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/opt/workspace/YOCTO/imx8-scarthgap/sources/poky/bitbake/bin/bitbake-worker", line 278, in child
    bb.utils.disable_network(uid, gid)
  File "/opt/workspace/YOCTO/imx8-scarthgap/sources/poky/bitbake/lib/bb/utils.py", line 1696, in disable_network
    with open("/proc/self/uid_map", "w") as f:
PermissionError: [Errno 1] Operation not permitted

ERROR: Task (virtual:native:/opt/workspace/YOCTO/imx8-scarthgap/sources/poky/meta/recipes-devtools/autoconf/autoconf_2.72e.bb:do_unpack) failed with exit code '1'
```

See [Ubuntu Bug 2056555](https://bugs.launchpad.net/ubuntu/+source/apparmor/+bug/2056555) for more details.

As a workaround apparmor "unprivileged_userns" profile can be temporarily disabled:

    sudo apparmor_parser -R /etc/apparmor.d/unprivileged_userns

### libxcrypt fails to build with host perl >= 5.38

Build of libxcrypt may fail with the error below:

```
| when is deprecated at /opt/workspace/YOCTO/v2x-kirkstone/bsp/build/tmp/work/armv8a-poky-linux/libxcrypt/4.4.28-r0/git/build-aux/scripts/BuildCommon.pm line 522.
| Compilation failed in require at ../git/build-aux/scripts/expand-selected-hashes line 28.
| BEGIN failed--compilation aborted at ../git/build-aux/scripts/expand-selected-hashes line 28.
| configure: error: bad value 'all' for --enable-hashes
| NOTE: The following config.log files may provide further information.
| NOTE: /opt/workspace/YOCTO/v2x-kirkstone/bsp/build/tmp/work/armv8a-poky-linux/libxcrypt/4.4.28-r0/build/config.log
| ERROR: configure failed
| WARNING: exit code 1 from a shell c

```

As a workaround a patch may be applied at `sources/poky` from the Yocto Mailing-list: [kirkstone-libxcrypt-fix-build-with-perl-5.38-and-use-master-branch.patch](https://patchwork.yoctoproject.org/project/oe-core/patch/20230726131331.2239727-1-Martin.Jansa@gmail.com/mbox/)

```
pushd sources/poky
git cherry-pick 2e4bdbc5c4330b3eeef14679166a5d908423ecd6
# solve conflicts
popd
```

### Build errors in libdnf-native / rust-llvm / ccache on Ubuntu 24.04

The newer versions of compilers and standard libraries on Ubuntu 24.04 are causing several toolchain packages to fail their build.

As a workaround install the Yocto `buildtools-extended` providing tested versions:

    pushd sources/poky
    ./scripts/install-buildtools \
    	--with-extended-buildtools \
    	--release yocto-4.0.27 \
    	--installer-version 4.0.27
    popd

Activate the buildtools in current shell:

    source sources/poky/buildtools/environment-setup-x86_64-pokysdk-linux

When using buildtools on ubuntu 24.04, also apply the workaround described above updating uninative.

### After `devtool modify` some packages fail to build with obscure git errors

When package sources are in the devtool workspace, yocto uses externalsrc.bbclass which uses deprecated `git submodule--helper` command:

```
...
  File "/usr/lib64/python3.6/subprocess.py", line 438, in run(input=None, timeout=None, check=True, *popenargs=(['git', 'submodule--helper', 'list'],), **kwargs={'stdout': -1, 'cwd': '/opt/workspace/YOCTO/imx8-kirkstone/build/workspace/sources/gpsd', 'env': {'HOME': '/home/josua-sr', 'LOGNAME': 'josua-sr', 'PATH': '/opt/workspace/YOCTO/imx8-kirkstone/sources/poky/scripts:/opt/workspace/YOCTO/imx8-kirkstone/sources/poky/bitbake/bin:/home/josua-sr/.local/bin:/home/josua-sr/.local/bin:/home/josua-sr/bin:/usr/local/bin:/usr/bin:/bin', 'PWD': '/opt/workspace/YOCTO/imx8-kirkstone/build', 'SHELL': '/usr/bin/zsh', 'USER': 'josua-sr', 'SSH_AUTH_SOCK': '/run/user/1001/gnupg/S.gpg-agent.ssh', 'BBPATH': '/opt/workspace/YOCTO/imx8-kirkstone/build', 'BB_ENV_PASSTHROUGH_ADDITIONS': 'ALL_PROXY BBPATH_EXTRA BB_LOGCONFIG BB_NO_NETWORK BB_NUMBER_THREADS BB_SETSCENE_ENFORCE BB_SRCREV_POLICY DISTRO FTPS_PROXY FTP_PROXY GIT_PROXY_COMMAND HTTPS_PROXY HTTP_PROXY MACHINE NO_PROXY PARALLEL_MAKE SCREENDIR SDKMACHINE SOCKS5_PASSWD SOCKS5_USER SSH_AGENT_PID SSH_AUTH_SOCK STAMPS_DIR TCLIBC TCMODE all_proxy ftp_proxy ftps_proxy http_proxy https_proxy no_proxy ', 'LC_ALL': 'en_US.UTF-8', 'GIT_INDEX_FILE': '/tmp/oe-devtool-indexs5pjg_rm'}}):
                 raise CalledProcessError(retcode, process.args,
    >                                     output=stdout, stderr=stderr)
         return CompletedProcess(process.args, retcode, stdout, stderr)
bb.data_smart.ExpansionError: Failure expanding variable do_compile[file-checksums], expression was ${@srctree_hash_files(d)} which triggered exception CalledProcessError: Command '['git', 'submodule--helper', 'list']' returned non-zero exit status 129.
The variable dependency chain for the failure is: do_compile[file-checksums]

ERROR: Parsing halted due to errors, see error messages above
```

This can be resolved locally by cherry-picking the [upstream fix in poky](https://git.yoctoproject.org/poky/commit/?id=0533edac277080e1bd130c14df0cbac61ba01a0c):

```
pushd sources/poky
git cherry-pick 0533edac277080e1bd130c14df0cbac61ba01a0c
popd
```

## Maintainer Notes

### Patching Linux / U-Boot / ATF / RCW / DPL / DPC / etc.:

Development is done in [lx2160a_build: branch "develop-ls-5.15.71-2.2.0"](https://github.com/SolidRun/lx2160a_build/tree/develop-ls-5.15.71-2.2.0) first, it serves as the reference BSP for HW validation.
Patches should be copied without changes from lx2160a_build to this layer.
