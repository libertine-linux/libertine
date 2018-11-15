// This file is part of libertine. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/libertine/master/COPYRIGHT. No part of libertine, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
// Copyright © 2018 The developers of libertine. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/libertine/master/COPYRIGHT.


#undef COMCONSOLE
#define COMCONSOLE COM1

#undef COMSPEED
#define COMSPEED 115200

// 8-N-1 (8 bits data, no parity, 1 stop bit)
#undef COMDATA
#define COMDATA 8
#undef COMPARITY
#define COMPARITY 0
#undef COMSTOP
#define COMSTOP 1
