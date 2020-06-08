use build_x86_64.sh for building os (x86_64)

For cloning the repo.

git clone --recurse-submodules https://github.com/arjuncr/minimal_x86_64_os.git

Update existing repo to latest.

git pull

git submodule update

Buiding os from source: (./build_x86_64.sh)
```
###################################################################################################

###################################Utility-1.5 to Build x86_64 OS##################################

###################################################################################################

Help message --help

Build and create iso: --build-img

Build All: --build-all

Rebuild All: --rebuild-all

Clean All: --clean-all

Wipe and rebuild --wipe-rebuild

Building kernel: --build-kernel --rebuild-kernel --clean-kernel

Building busybx: --build-busybox --rebuild-busybox --clean-busybox

Building other soft: --build-other --rebuild-other --clean-other

Creating root-fs: --create-rootfs

Create ISO Image: --create-img

Cleaning work dir: --clean-work-dir

Test with Qemu --Run-qemu

######################################################################################################
```

Build 64 bit:  

./build_x86_64.sh --build-img 4 64  

Build 32 bit:

./build_x86_64.sh --build-img 4 32    
