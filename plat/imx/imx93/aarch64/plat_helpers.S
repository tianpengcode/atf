/*
 * Copyright 2022-2023 NXP
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <asm_macros.S>
#include <cortex_a55.h>

#include <platform_def.h>

	.globl	plat_is_my_cpu_primary
	.globl	plat_my_core_pos
	.globl	plat_calc_core_pos
	.globl	platform_mem_init

	/* ------------------------------------------------------
	 * Helper macro that reads the part number of the current
	 * CPU and jumps to the given label if it matches the CPU
	 * MIDR provided.
	 *
	 * Clobbers x0.
	 * ------------------------------------------------------
	 */
	.macro  jump_if_cpu_midr _cpu_midr, _label

	mrs	x0, midr_el1
	ubfx	x0, x0, MIDR_PN_SHIFT, #12
	cmp     w0, #((\_cpu_midr >> MIDR_PN_SHIFT) & MIDR_PN_MASK)
	b.eq	\_label

	.endm

	/* ----------------------------------------------
	 * unsigned int plat_is_my_cpu_primary(void);
	 * This function checks if this is the primary CPU
	 * ----------------------------------------------
	 */
func plat_is_my_cpu_primary
	mrs	x0, mpidr_el1
	mov_imm x1, MPIDR_AFFINITY_MASK
	and	x0, x0, x1
	cmp	x0, #PLAT_PRIMARY_CPU
	cset	x0, eq
	ret
endfunc plat_is_my_cpu_primary

	/* ----------------------------------------------
	 * unsigned int plat_my_core_pos(void)
	 * This function uses the plat_calc_core_pos()
	 * to get the index of the calling CPU.
	 * ----------------------------------------------
	 */
func plat_my_core_pos
	mrs	x0, mpidr_el1
	mov	x1, #MPIDR_AFFLVL_MASK
	and	x0, x1, x0, lsr #MPIDR_AFF1_SHIFT
	ret
endfunc plat_my_core_pos

	/*
	 * unsigned int plat_calc_core_pos(uint64_t mpidr)
	 * helper function to calculate the core position.
	 * With this function.
	 */
func plat_calc_core_pos
	mov	x1, #MPIDR_AFFLVL_MASK
	and	x0, x1, x0, lsr #MPIDR_AFF1_SHIFT
	ret
endfunc plat_calc_core_pos

func platform_mem_init
	ret
endfunc platform_mem_init
