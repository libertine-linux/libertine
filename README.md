# Libertine Linux: Simplicity is Security

A secure, built-from git-controlled source Linux system that is fully auditable and runs solely from RAM.

Produces ready-to-run images that consist of just one file ready to be booted using grub, pxeboot or QEMU with an embedded copy of all required software inside a read-only init disk.


## Why?

I like the idea of having one system, doing one thing well, that can be stored entirely in source control. That rebuilds as the same system every time from minimal dependencies. And that has zero administration. I want a system I control which version goes where. So that means no package manager arbitarily ----ing things up (eg when homebrew's switch of llvm version from 3.8 to 3.9 wasted me a day). Instead our 'packages' are just folders in git, with submodules for the upstream sources.

I want a system I can just boot and use from RAM via PXE or QEMU / KVM. So I can deploy a large cluster, and upgrade machines by just rebooting or by using `kexec`. Reboot to upgrade means I don't have to think whether that CVE fix to glibc means I have to restart all services or just those services and in what order. If the Linux install is small and simple, this will actually be quicker - and it won't need an admin logging onto boxes. That means having a kernel with a builtin initramfs and command line, so there are no external dependencies.

I want a system where I can patch a critical component - say the shell - by just a fork in git. That means avoiding release tarballs, and taking charge of the GNU 'Build System' auto-guff. Making sure a bug in automake doesn't make a CVE in my OS. It means being able to rebuild the entire OS, and self-bootstrap, from almost nothing. Right now, Libertine Linux works with just a C/C++ system compiler (with associated binutils) and BusyBox. It doesn't even need make, perl or auto-shaft installed. It builds its own toolchain from scratch (including core utils), and so captures all those subtle inputs that the build environment can influence in the output.

I also like simple DevOps, and the ability to make the OS and the software I deploy one and the same. The idea of taking an OS that really is effective for the desktop, and using it for a server, is not sensible; the recent debacle of systemd shows us how confusing that can become. Instead, the right place to look for low maintainance, secure systems is the embedded space and the supercomputing space. Many of the design decisions in Libertine Linux are from my experience of building internet-scale, large deployment clusters and high performance, reliable and robust software over the last twenty years.

Lastly, though, the development of Libertine Linux debunks the mantra that the bazaar is better than the cathedral; it's not. The lack of coherent end-to-end thinking (from computer scientist with a clever algo, to system administrator patching security holes, via kernel and system and application software developers) is why we have complex, brittle and insecure systems today. Too few of us have enough experience or interest to see from one end to the other. And none have the time or finances to count. Too few place value on what they perceive as the little things - consistency, organization and communication - and instead retreat into jargon and flame wars. Until superb programming is equated more with fine art and the best examples of literature, and not historic and strange practices, security and integrity will suffer. I am as guilty as most; just look at some of my descriptions below!


## Quick Start

	git clone https://github.com/lemonrock/libertine.git
	cd libertine
	
	# This script tries to use ssh-keygen to generate RSA and ED25519 keys for the 'example' machine.
	./run-after-clone
	
	# Wait a long time
	
	# Run inside docker
	./libertine-docker -v 2
	
	# Test using qemu (requires qemu-system-x86_64 to be present)
	./test-with-qemu
	
	# Now log on to the console with a root password of 'helloworld'; by default root logins by password disabled (as they are for all users)

If you don't want to use docker, you can just run directly with `./libertine -v 2`. This has only been tested on Alpine Linux 3.8.

To see what's going on, take a look at the files in `machines`. If you copy the `example` machine folder, you can start work on your own. Machine names should be simple; DNS hostnames work best.


## Key Features

* Recreate any server exactly from source control: Everything is built from source
	* This allows total versioning - something not other system using a package manager can achieve
	* Use source control administrative policies to control all server definitions in your estate
	* Cryptographic hashes are used to determine if rebuilds are required (like NixOS, but without the package management)
	* Sadly this is not true for anything using `npm`; currently this is just grafana
* Everything runs from RAM; disk is only used for persistent data if configured
	* All data is lost on power off
	* No need for a initrd, disk, etc; everything is inside one linux kernel image
* Boots over the network using PXE
	* Ideal for large server farms and clouds like Vultr.
	* Upgrade by simply rebooting or by kexec
	* True PXE - not just PXE for installation
* Boots in KVM and QEMU by just passing `qemu-system-x86_64 -kernel my-machine-kernel.vmlinuz`
	* Kvm / Qemu settings can be managed as part of source control
	* Empty drives for persistent storage can be created on first boot (see `montebianco/montebianco-qemu`)
* Extremely Secure
	* Kernel is built with PaX and grsecurity
		* With full protections; for instance, the TCP stack always plays dead
	* No loadable modules; highly resistant to module-based rootkit attacks
	* No loadable firmware; all necessary firmware is compiled into the Kernel
		* `CONFIG_EXTRA_FIRMWARE` can be set to the exact set required (eg `CONFIG_EXTRA_FIRMWARE="amd-ucode/microcode_amd_fam15h.bin"`)
		* We use a git-versioned source of firmware
	* ~~Persistent storage uses encrypted ZFS~~
		* ZFS is currently broken for a grsecurity-patched Linux
	* No package manager
		* No way to install packages at runtime
	* No unnecessary packages with an extremely small footprint
		* Lets you audit and understand exactly what's there
		* `.so`, (`lib`), `man`, `info`, headers, etc not installed
		* Uses busybox over GNU utilities; may switch to Toybox when that is viable in a couple of years
		* Useless legacy cruft not installed (`su`, floppy disk programs, `chat`, `cal`, `ftp`, `telnet` etc)
		* Only the desired timezone data (UTC by default) and keyboard maps and console fonts installed
	* All libraries are statically linked; .so symlink attacks and `LD_PRELOAD` are impossible
		* With the exception of `nodejs`, which simply doesn't work with common modules in this case (eg `node-sass`)
		* With the exception of bespoke builds of `luajit`, which need to use `dlopen()`
	* Compilation uses hardened settingd
		* Full RELRO (`-Wl,-z,relro,-z,now`)
		* Uses a strong stack smashing protector (`-fstack-protector-string`)
		* Uses `_FORTIFY_SOURCE`
		* Uses Position-Independent-Executables for statically linked binaries, aka 'static PIE'
			* ~~Breaks ZFS on Linux (eg `zed`) and OpenSSH~~
	* Kernel auditing enabled
		* Used by OpenSSH (which is an optional dependency)
		* Used by Sudo (which is an optional dependency)
	* Everything goes to syslog wherever and whenever possible
	* Choose to have root with a password or not, but
		* Root logins only possible on the console
	* No suid binaries
		* ping does not need to run as root
		* except for `sudo` - which is an optional dependency
		* There is no `su`
	* Login shells have an inactivity timeout enforced of 5 minutes
	* Kernels can have built in command lines which can not be overridden on boot
		* Use this to increase isolation from the pre-boot environment and bootloaders
	* Inbound and Outbound firewalls are always on
	* Syslogging uses TLS 1.2 over TCP with very modern cipher suites
		* UDP is disabled except for localhost
		* TCP is never used except with TLS 1.2
		* By default, all logs are always shipped to a central syslog server; this could also be logstash or whatever
	* Libressl is the preferred TLS library
		* libressl (library and binary) and curl have been patched to have far more robust default ciphers
			* Both have been patched to `ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256`
			* This can be overriden by configuration
			* This change affects all dependents, such as `git`, `syslog-ng`, BusyBox `wget` and others
			* Previously libressl (both library and binary) was `ALL:!aNULL:!eNULL:!SSLv2`
			* Previously curl was `LL:!EXPORT:!EXPORT40:!EXPORT56:!aNULL:!LOW:!RC4:@STRENGTH`
		* Only Perfect Forward Securcy ciphers are enabled wherever possible
			* ChaCha20 is preferred with AES-GCM a close second
		* This change leaves ***nodejs vulnerable***, especially as ***npm*** (as it uses an internal ssl library)
		* Likewise, ***go binaries are probably vulnerable***
		* ***nodejs*** is very vulnerable, because iy uses it's own built-in openssl with features *only* supported by openssl
			* And the attitude of the developers to recitfying this is poor: <https://github.com/nodejs/node/issues/428>
			* Many of Node JS's CVEs are because of this
			* Having built node.js, and had many issues with it and related tools, I have come to the conclusion that it's garbage
			* ***DO NOT USE UNLESS YOU HAVE TO***
* Custom kernels fully supported
	* Build only the support in you need for maximum security
* No systemd
	* All daemons start at init and stop at shutdown; no need for anything complex whatsoever
	* All daemons run using source'd shell scripts
	* Basic PID 1 init supplied by BusyBox's robust, tried-and-tested `init`
	* No runlevels; they're pointless
	* `inittab` used only for starting and stopping
* Essential daemons only run in the base build, but there's no need to use them
	* Simply define your own base build
	* Daemons are not even included in the build if they're disabled in busybox's config
* No need for swap, encryption or complex mounts; no switch root or pivot or the like
* Many Network Features supported out-of-the-box
	* Uses easy to work with `ifupdown`
	* Traffic Shaping
	* NIC Bonding (Teaming)
	* VLANs
	* MVLANs
	* Bridges
	* Static Routes
	* Tunnels (TUN devices)
	* ~NFTables Firewalls~ (and hence legacy iftables)
		* To do
	* By default, we use a large list of known spam, etc hosts and block them with duff entries in `/etc/hosts`.
* The set of software packages and their configuration for a machine, are just plain text files and so are easy to store in source control
	* All files like `/etc/hosts` are created at compile time from snippets in folders like `/etc/hosts.d/*.hosts`
		* No need to ever edit them
		* Different packages can contribute different snippets
		* This allows configuration to be 'built up'
		* Same approach is used for `/etc/passwd`, `/etc/group` etc, allowing as much as possible to live in source control as plain text files.
	* Downstream packages can override any snippet, if you don't like it, just create a file with the same name
	* The set of snippets to combine are extensible; just have your package drop a `my-package-name.combine` file in `/etc/combine.d`
	* Current snippeted features in the baseline filesystem (package `libertine_filesystem`) include:-
		* `/etc/binfmt.d`
			* used in shell glob sort order
		* `/etc/combine.d`
			* used in shell glob sort order to work out what to combine - this is the 'master' list
		* `/etc/ethers.d`
		* `/etc/filesystems.d`
			* Used by `mount` as an override to /proc/filesystems
			* Not created if contents would be empty
		* `/etc/fstab.d`
		* `/etc/group.d`
			* Currently does not correctly combine multiple group entries
		* `/etc/gshadow.d`
			* Not very useful
		* `/etc/hosts.d`
		* `/etc/issue.d`
		* `/etc/mactab.d`
			* used by `ifname` before bringing up an interface to rename it based on a MAC address
		* `/etc/mdev.conf.d`
		* `/etc/motd.d`
		* `/etc/networks.d`
		* `/etc/nologin.txt.d`
		* `/etc/passwd.d`
		* `/etc/protocols.d`
		* `/etc/securetty.d`
		* `/etc/services.d`
		* `/etc/shadow.d`
		* `/etc/shells.d`
		* `/etc/sysctl.conf.d`
			* used in shell glob sort order
		* `/etc/iproute2/rt_dsfield.d`
		* `/etc/iproute2/rt_protos.d`
		* `/etc/iproute2/rt_realms.d`
		* `/etc/iproute2/rt_scopes.d`
		* `/etc/iproute2/rt_tables.d`
		* `/etc/network/interfaces.d`
		* `/etc/network/staticroutes.d`
		* `/etc/network/traffic-control/class/add.d`
			* Used by `tc`
		* `/etc/network/traffic-control/filter/add.d`
			* Used by `tc`
		* `/etc/network/traffic-control/qdisc/add.d`
			* Used by `tc`
		* `/etc/profile.d` (used uncombined)
		* `/etc/acpi.map.d` (combined at daemon launch time)
		* `/etc/acpid.conf.d` (combined at daemon launch time)
		* `/etc/ntp.conf.d` (combined at daemon launch time)
		* `/etc/syslogd.conf.d` (combined at daemon launch time)
		* `/etc/crontab.d` (combined at daemon launch time)
	* Additional snippets can be added by adding files to `/etc/combine.d`
		* Each entry is a line denoting the root folder, the file to create, its permissions and the type of combining
		* `/etc passwd 0600 password` means look for combine files in `/etc/passwd.d` to create `/etc/passwd` as 0600 and combine them using the `passwd` type of combining
		* It also means that the files to be combined will have their permissions changed to 0600
		* The types of combining are:-
			* `nosort` - just concatenate the files together in glob-search order
			* `default` - concatenate the files together with lines sorted
			* `hasfiles` - only combine if at least one file is present
			* `nocombine` - do not combine
			* `passwd` - for the passwd file `/etc/passwd`
			* `shadow` - for shadow files, such as `/etc/shadow` and `/etc/gshadow`
			* `group` - for the group file `/etc/group`
	* The following are used as snippets by native programs:-
		* `/etc/network/if-pre-down.d`
		* `/etc/network/if-down.d`
		* `/etc/network/if-post-down.d`
		* `/etc/network/if-pre-up.d`
		* `/etc/network/if-up.d`
		* `/etc/network/if-post-up.d`
		* `/etc/network/ifplugd/link-down.d`
		* `/etc/network/ifplugd/link-up.d`
		* `/etc/network/ifplugd/link-error.d`
		* `/etc/network/iproute2/rt_dsfield` (note there is no trailing `.d`)
		* `/etc/network/iproute2/rt_realms` (note there is no trailing `.d`)
* Random entropy is increased at boot time by downloading (over https) from random.org
	* *Sadly currently not reliable*
	* We do not use Ubuntu's pollinate service as it is far too Ubuntu-specific
	* We would like to add support for tpm-tools
	* Where possible, grsecurity is used to increase kernel entropy
* Language choices and preferences
	* For today: C, or C++ if we have to
	* For the future: Rust and, if we have to, Go
	* For everthing requiring glue: POSIX sh (not bash)
	* For complex or performant scripting: Lua (as LuaJIT)
	* Just come with too many issues and complexity creating insecurity: Legacy cruft like Perl or M4, horrible like JavaScript or PHP, difficult to deploy like Python or just uggh, Ruby
		* Note that perl and m4 are implicitly used becayse building Linux and anything using Autocruft needs them
* Real Time Clock (RTC) is always assumed to be UTC. Running a BIOS clock in local time is a great way to create problems.


## Creating a new machine

A 'machine' is simply a folder containing files that describe how it is to be configured and what software packages to build for it and how. These files and their permissions are used to create a cryptographic hash; consequently, if the configuration files change, the machine is considered to have changed and can be rebuilt.

The file system layout of these files is as follows:-

```bash
machines/
	my_machine_name/
		.gitignore
		package-configurations/
			<files ending .conf or .mkdir>
			...
		packages/   (usually a symlink)
		settings/
			architecture
			initramfs.contents
			packages.list
			compiler-flags/
				build-c.compiler-flags
				build-cxx.compiler-flags
				host-c.compiler-flags
				host-cxx.compiler-flags
			initramfs/
				<files and folders to copy onto the initial initramfs>
		qemu/
			qemu.config
			qemu-extra.config
			<any hard disk files ending in .qcow2>
			libertine-linux.vmlinuz   (usually a symlink)
```


### `.gitignore`

An optional file to ignore anything that should not go in source control, eg private keys stored intside the `initramfs/` folder.


### `package-configurations`

A small number of packages can be configured in different ways using one of two kinds of files: `.config` and `.mk`


#### `.config` files

These are named as `<package>.config` (where `<package>` is a software package name) and are shell script files which are `source`'d by `<package>` when it is built. They typically contain shell script variables which can be set to different values to control the package output. If a `.config` file is missing, the package's build will use sensible defaults. Since these files are shell script, they can contain empty lines and comments starting with `#`.


#### `.mk` files

These are used by a very small number of packages that use a linux-like makefile configuration system. Currently this is restricted to the packages `build_busybox`, `busybox` and `linux_prep` (The name used to separate builds of Linux source code from builds of the Linux kernel with an embedded initramfs disk). By default, these are relatively symlinked to default files supplied by the said packages, but can be overridden by local copies if desired.


### `packages`

This is usually a symlink to a git-controlled folder of packages, typically from <https://github.com/libertine-linux/packages>. However, this need not be the case.


### `settings`


#### `architecture`

This file contains just one line (with no terminal line feed) containing the architecture of the machine being built, eg `x86_64`. At this time no other architectures have been successfully tested, although support for 64-bit ARM (`aarch64`) is desirable.


#### `initramfs.contents`

This file is a Linux kernel configuration file that changes the permissions and user and group ids (uid and gid) of files and special files (eg devices) that are present in the initramfs disk. It may contain comments lines starting with `#`. For example:-

```
file /etc/ssh/ssh_host_ecdsa_key initramfs/etc/ssh/ssh_host_ecdsa_key 0400 0 0
file /etc/ssh/ssh_host_ed25519_key initramfs/etc/ssh/ssh_host_ed25519_key 0400 0 0
file /etc/ssh/ssh_host_rsa_key initramfs/etc/ssh/ssh_host_rsa_key 0400 0 0
file /etc/ssh/sshd_authorized_keys/raph initramfs/etc/ssh/sshd_authorized_keys/raph 0400 0 0
dir /home/raph 0700 1000 1000
dir /srv/httpd/myhttpdsite 0500 89 89
# rcS will change the uid:gid to 89:89 as part of boot
file /srv/httpd/myhttpdsite/index.html initramfs/srv/httpd/myhttpdsite/index.html 0400 89 89
```

Individual packets may also generate similar files, and the resultant file given the to the Linux kernel build process is a composite.


#### `packages.list`

This is a file listing the software packages (in `packages/`) to build and install. Blank lines are ignored, and lines may be commented by starting them with `#`.


#### `compiler-flags/`

This folder contains files used to make performance and other optimizations when compiling using the C and C++ compilers (and, in the future, possibly the Rust compiler).

All of the files here follow the same structure, and have one command line argument per line. For example, a typical file for controlling builds of code that will end up in the final initramfs disk image might be:-

```
-static
--static
-Wl,-Bstatic
-static-libgcc
-Werror=implicit-function-declaration
-Wl,-z,relro,-z,now
-fstack-protector-strong
-D_FORTIFY_SOURCE=2
-D_GNU_SOURCE
-D__gnu_linux__
-O3
-fno-asynchronous-unwind-tables
-fno-unwind-tables
-ffunction-sections
-fdata-sections
-Wl,--gc-sections
-fno-common
-fomit-frame-pointer
```

Blank lines and comments are not allowed and the final line *must* end with a line feed.

The files used are:-

* `build-c.compiler-flags`: These are flags to be used by the C compiler used when building the initial bootstrap toolchain.
* `build-cxx.compiler-flags`: There are flags to be used by the C++ compiler used when building the initial bootstrap toolchain.
* `host-c.compiler-flags`: These are flags to be used by the C compiler when creating binary code to be used in the resultant Libertine Linux initramfs disk image; they should normally contain optimizations.
* `host-cxx.compiler-flags`: These are flags to be used by the C++ compiler when creating binary code to be used in the resultant Libertine Linux initramfs disk image; they should normally contain optimizations.


#### `initramfs/`

These are machine-specfic files to be put into the resultant Linux initramfs disk image. The folder structure inside this folder is preserved as-is, although permissions, user ids and group ids can be overridden using the `initramfs.contents` file. A typical thing to include might be SSH host private keys, machine specific configuration for syslog or sysctl, network interface configuration, static HTTP content to serve and the like. Nothing that requires a writable disk at runtime should be in here.

Content that should not end up in source control (git), eg SSH private keys, should be explicitly ignored using `.gitignore`, or a solution such as `git-crypt` used.


### `qemu`

This is an optional folder for testing using QEMU using the `test-under-qemu` program.


#### `qemu.config`

This is a standard QEMU INI-style configuration file.


#### `qemu-extra.config`

This is `.config` shell script file in the style used for `package-configurations/` that allows customization of the QEMU command line through 3 functions:-

* `test_with_qemu_cpu IvyBridge` sets the CPU to use (in this example, to `IvyBridge`).
* `test_with_qemu_keyboard en-us` sets the keyboard layout to use (in this example, to `en-us`)
* `test_with_qemu_drive 0 1G qcow2 lazy_refcounts` adds a drive, number `0`, with capacity `1G` in format `qcow2` with an option of `lazy_refcounts`. This function can be called more than once; it will create drive image files if they do not exist in the `qemu` folder called `drive.<N>.qcow2` where `<N>` is the drive number, eg `0`. It would be good practice to not check these into git and use `.gitignore` (above) to ignore them, eg with `*.qcow2`.


### `libertine-linux.vmlinuz`

This should be a symlink to the Libertine Linux kernel image produced by `./libertine`. Typically it would be the value `../../../output/<MACHINE>/libertine-linux.vmlinuz` where `<MACHINE>` is your machine name, eg `my_machine`.


### Use Cases

* Servers
	* OpenLDAP
	* OpenSMTPD
	* DNS (dnsmasq and dnsd)
	* MQTT
	* Basic HTTP with shell scripting out of the box (note: basic sh, not bash, but not useful for more than basic infrastructure automation although it is also be possible to use Lua via LuaJIT)
* Embedded Devices
* Internet of Things Appliances

That's it.


### Building

* A build of Libertine Linux can use Docker on Mac OS X, Windows and Linux.
* A build of Libertine Linux assumes a minimal Linux-orientated host system, and has only been tested on Alpine Linux 3.6 and 3.8:-
	* To build on Alpine Linux, install the essential tools with `sudo apk add alpine-sdk`
	* On a more traditional Linux system, you'll need `binutils`, `gcc`, `g++`, `libc-dev`, `coreutils`, `findutils`, `sed` (POSIX), `grep` (POSIX) and `awk` (POSIX).
	* In theory, it should be possible to build on Mac OS X but someone needs to fix GNU binutils `ld` (BFD variant) to compile on it and adjust the latest version of BusyBox
* A build does not need `make`, `bison`, `flex`, `yacc`, `lex`, `perl`, `autoconf`, `automake`, `m4` or `bash`; we bootstrap these to known versions
* We try to minimise use of the host's C compiler toolchain, but gcc's insane dependencies makes this hard
* The build system self-bootstraps most of its dependencies, including GNU make and patch; it is independent of the host system except for a POSIX shell (`sh`), `/usr/bin/env`
* To build a replacement native build toolchain (and the run `libertine`), the following are necessary:-
	* System Compiler and Binutils
		* `ar`
			* BusyBox `ar` is unlikely to work
		* `c++`
		* `cc`
			* Note that `cc` and `c++` also require a linker, system headers and system libraries
			* `cc` must also be a preprocessor via the `-E` switch
			* In practice all modern C compilers (GCC, Clang) support these requirements
		* `ld`
		* `objdump`
		* `ranlib`
		* `readelf`
	* Grep-Awk-Sed (all capable of being supplied by BusyBox)
		* `awk`
		* `grep`
		* `sed`
	* Find Utilities (all capable of being supplied by BusyBox)
		* `find`
		* `xargs`
	* POSIX shell (BusyBox ash works)
		* `sh`
	* Common utilities (all capable of being supplied by BusyBox)
		* Very Common
			* `cat`
			* `chmod`
			* `chown`
			* `cp`
			* `cut`
			* `env`
			* `head`
			* `id`
			* `ln`
			* `ls`
			* `mkdir`
			* `mktemp`
			* `mv`
			* `rm`
			* `rmdir`
			* `sleep`
			* `stat`
			* `tail`
			* `tr`
		* Very Common but should be done with shell script
			* `basename`
			* `dirname`
			* `echo`
			* `touch` (only being used to create empty files)
		* Common
			* `base64`
			* `install`
			* `od`
			* `sha256sum`
		* Comparison Utilities
			* `cmp`
		* Sort Utilities
			* `sort`
			* `uniq`
		* Not Essential but used if present to avoid corner case bugs by `./libertine`
			* `realpath` or `readlink`


### TODO

* Add support for ext4 encryption using <https://github.com/gdelugre/ext4-crypt> and `e2fsprogs`.
* Remove grsecurity support and update the kernel, potentially using the CLIP-OS branch


### Notes

* Non-root-logins on the console can be prevented by creating the file `/etc/nologin`; it can be empty. Line feeds in this file are automatically converted to CRLF sequences. This file can be created by a downstream package if desired.
* Builds are not yet fully reproducible. Some GNU-inspired builds use tools like `hostname`, `dnsdomainname`, `uname`, `id` and `date`. The plan is to eventually eliminate these.
	* So far, `hostname`, `dnsdomainname` and `uname` have been eliminated by using a fake that returns data we control.
* We actually go as far as intercepting usages of `#!/bin/sh` and the like to try to force code to use our own, known-version, toolchain version of busybox sh, perl, etc. Sadly this isn't perfect.
* git is not required to build, but package versioning uses git hashes by interrogating `.git` folders. If `.git` folders aren't present, we default to a hash of all the files and folders and their permissions.


#### Networkings

* Uses the conventional method from Debian et al, and is very similar to that in [Alpine Linux](https://wiki.alpinelinux.org/wiki/Configure_Networking)
	* Supports bonding
	* Uses snippets in /etc/network/interfaces.d
* Traffic control is automatic
	* Uses snippets in /etc/network/traffic-control/*/*.d/*
	* Snippets are prefixed with a variant and action, eg snippets in `/etc/network/traffic-control/qdisc/add.d`, named `*.add`, will be invoked as `tc qdisc add <line>`, where `<line>` is a line inside the snippet. A snippet can have one or more lines.
* Static routing
	* Can use /etc/network/interfaces.d
	* Can also use /etc/network/staticroutes.d

#### Files not copied to initram (rootfs)

* `.DS_Store`, `.gitignore` (but containing folders are), `._*` (a Mac OS X ism from using NFS)
* Anything ending `.disabled`
* `README` and anything matching `README.*`

#### Unsupported BusyBox Daemons

The following daemons provided in BusyBox are not supported because they are either insecure, obsolete or use `inetd`:-

* `tftpd`
* `ftpd`
* `telnetd`
* `fakeidentd`
* `inetd`
	* `echo`
	* `discard`
	* `time`
	* `daytime`
	* `chargen`

The following unsupported daemons may be supported if a reasonable use case is found for them:-

* `tcpsvd`
* `udpsvd`


## License

The license for this project is MIT. Individual files and, of course, upstream sources and packages, may be covered by other (open source currently) licenses. Much gratitude is expressed for the authors of all the code contained in Libertine Linux, and particularly for the original work made by the authors of Alpine Linux, without known of whom this would have not been possible.


## Packages

### To Document

* `variant`
* `copy_subset`
* `libertine_public_libtool`
* `depends`
* `build_needs`
* `build_provides`
	* Not checked until after build finished
* `libertine_compile_<packageName>`
	* `<packageName>` must be A-Z a-Z 0-9 and underscore
* Layout, copying of files
	* `misc` `input-sysroot`, `initramfs`, `initramfs.contents`
* Special handling of `build_` packages
* Function documentation
* How PATHS and ccache work
* Machine hashes
* Machine configuration (.config and .mk (menuconfig))
* Application of patches

### Not supported
* Circular dependencies (and not detected)
* Package conflicts (eg autoconf264 and autoconf)
