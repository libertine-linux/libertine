// This file is part of libertine. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/libertine/master/COPYRIGHT. No part of libertine, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
// Copyright © 2018 The developers of libertine. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/libertine/master/COPYRIGHT.


#undef LOG_LEVEL
#define LOG_LEVEL LOG_NONE

// Not documented
#undef CONSOLE_EFI
#define CONSOLE_EFI

// Not documented
#undef CONSOLE_LINUX
#define CONSOLE_LINUX

// Unusual consoles include CONSOLE_FRAMEBUFFER (visual display), CONSOLE_DEBUGCON, CONSOLE_INT13, CONSOLE_DIRECT_VGA and CONSOLE_PC_KBD

#undef CONSOLE_PCBIOS
#define CONSOLE_PCBIOS ( CONSOLE_USAGE_STDOUT | CONSOLE_USAGE_DEBUG | CONSOLE_USAGE_TUI )

#define CONSOLE_SERIAL ( CONSOLE_USAGE_STDOUT | CONSOLE_USAGE_DEBUG | CONSOLE_USAGE_TUI )
#define CONSOLE_SYSLOGS ( CONSOLE_USAGE_STDOUT | CONSOLE_USAGE_DEBUG | CONSOLE_USAGE_LOG )
#define CONSOLE_VVMWARE ( CONSOLE_USAGE_STDOUT | CONSOLE_USAGE_DEBUG | CONSOLE_USAGE_LOG )

#undef KEYBOARD_MAP
#define KEYBOARD_MAP us
