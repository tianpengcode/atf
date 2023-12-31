/*
 * Copyright (c) 2017-2021, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <assert.h>

#include <platform_def.h>

#include <common/debug.h>
#include <common/fdt_fixup.h>
#include <lib/mmio.h>
#include <lib/psci/psci.h>

#include <sunxi_cpucfg.h>
#include <sunxi_private.h>

static bool psci_is_scpi;

#if SUNXI_PSCI_USE_SCPI
bool sunxi_psci_is_scpi(void)
{
	return psci_is_scpi;
}
#endif

#ifndef SUNXI_ALT_RVBAR_LO_REG
#define SUNXI_ALT_RVBAR_LO_REG(n)	0
#define SUNXI_ALT_RVBAR_HI_REG(n)	0
#endif

int sunxi_validate_ns_entrypoint(uintptr_t ns_entrypoint)
{
	/* The non-secure entry point must be in DRAM */
	if (ns_entrypoint < SUNXI_DRAM_BASE) {
		return PSCI_E_INVALID_ADDRESS;
	}

	return PSCI_E_SUCCESS;
}

int plat_setup_psci_ops(uintptr_t sec_entrypoint,
			const plat_psci_ops_t **psci_ops)
{
	assert(psci_ops);

	/* Program all CPU entry points. */
	for (unsigned int cpu = 0; cpu < PLATFORM_CORE_COUNT; ++cpu) {
		if (sunxi_cpucfg_has_per_cluster_regs()) {
			mmio_write_32(SUNXI_CPUCFG_RVBAR_LO_REG(cpu),
				      sec_entrypoint & 0xffffffff);
			mmio_write_32(SUNXI_CPUCFG_RVBAR_HI_REG(cpu),
				      sec_entrypoint >> 32);
		} else {
			mmio_write_32(SUNXI_ALT_RVBAR_LO_REG(cpu),
				      sec_entrypoint & 0xffffffff);
			mmio_write_32(SUNXI_ALT_RVBAR_HI_REG(cpu),
				      sec_entrypoint >> 32);
		}
	}

	if (sunxi_set_scpi_psci_ops(psci_ops) == 0) {
		INFO("PSCI: Suspend is available via SCPI\n");
		psci_is_scpi = true;
	} else {
		INFO("PSCI: Suspend is unavailable\n");
		sunxi_set_native_psci_ops(psci_ops);
	}

	return 0;
}
