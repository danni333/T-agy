# T-agy (agy-termux)

Native Builder & Patcher for Google Antigravity (agy) on Android Termux.

This project allows compiling **Google Antigravity** natively directly on your Android phone inside the native Termux environment (no PRoot, no chroot, no virtualization), bypassing the immediate memory allocator segmentation faults (`SIGSEGV` / `tcmalloc` limits) inherent in Android kernel paging schemas.

## The Problem
Google's official `agy` command-line utility uses `tcmalloc` or direct linkage to dynamic C++ allocators using CGO. These allocators rely heavily on 48-bit pointer tagging. Since standard Android kernels limit virtual address spaces down to 39 bits, any execution of compiled binaries that link with `tcmalloc` crashes instantly on load.

## The Solution
`T-agy` implements:
1. An environment bootstrapper (`install.sh`) to fetch needed environment toolchains (`golang`, `git`, `curl`).
2. A custom Manager / Proxy wrapper written in Go (`manager/main.go`) which automatically checks for releases, downloads the code, and applies a **Memory Patching Algorithm**:
   - Comments out `tcmalloc` references from `go.mod`.
   - Modifies memory linkages on Go files to skip problematic CGO setups under Android.
   - Triggers native compilation programmatically using the target architecture variables combined with strict `CGO_ENABLED=0` to force safe pure-Go `mmap` mapping, adapting natively to the 39-bit Android virtual limit.

## Installation / Usage

Launch your Termux shell and run:

```bash
curl -sSf https://raw.githubusercontent.com/danni333/T-agy/main/install.sh | bash
```

Once installed, use:
- `agy-termux --update-core` (or simply `agy --update-core`) to fetch, patch, and build Google Antigravity.
- `agy [arguments]` to transparently pass commands straight down to compiled native binaries.
