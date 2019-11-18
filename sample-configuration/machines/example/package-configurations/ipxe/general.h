// This file is part of libertine. It is subject to the licence terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/libertine/master/COPYRIGHT. No part of libertine, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
// Copyright © 2018 The developers of libertine. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/libertine/master/COPYRIGHT.


#undef DOWNLOAD_PROTO_TFTP
#define DOWNLOAD_PROTO_HTTPS
#define NET_PROTO_IPV6

#undef IMAGE_PNG

// Disable wireless
#undef CRYPTO_80211_WEP
#undef CRYPTO_80211_WPA
#undef CRYPTO_80211_WPA2
#undef IWMGMT_CMD

// Disable infiniband
#undef IBMGMT_CMD
#undef VNIC_IPOIB

#undef SANBOOT_CMD

#define CERT_CMD
#define CONSOLE_CMD
#define IMAGE_TRUST_CMD
#define IPSTAT_CMD
#define LOTEST_CMD
#define NEIGHBOUR_CMD
#define NSLOOKUP_CMD
#define NTP_CMD
#define PARAM_CMD
#define PCI_CMD
#define PING_CMD
#define POWEROFF_CMD
#define PROFSTAT_CMD
#define REBOOT_CMD
#define TIME_CMD
#define VLAN_CMD