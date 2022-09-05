/*
 * Copyright (c) 2021-2022, Arm Limited. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <arch.h>
#include <asm_macros.S>
#include <common/bl_common.h>
#include <cortex_makalu_elp_arm.h>
#include <cpu_macros.S>
#include <plat_macros.S>
#include "wa_cve_2022_23960_bhb_vector.S"

/* Hardware handled coherency */
#if HW_ASSISTED_COHERENCY == 0
#error "Cortex Makalu ELP must be compiled with HW_ASSISTED_COHERENCY enabled"
#endif

/* 64-bit only core */
#if CTX_INCLUDE_AARCH32_REGS == 1
#error "Cortex Makalu ELP supports only AArch64. Compile with CTX_INCLUDE_AARCH32_REGS=0"
#endif

#if WORKAROUND_CVE_2022_23960
	wa_cve_2022_23960_bhb_vector_table CORTEX_MAKALU_ELP_ARM_BHB_LOOP_COUNT, cortex_makalu_elp_arm
#endif /* WORKAROUND_CVE_2022_23960 */

	/* ----------------------------------------------------
	 * HW will do the cache maintenance while powering down
	 * ----------------------------------------------------
	 */
func cortex_makalu_elp_arm_core_pwr_dwn
	/* ---------------------------------------------------
	 * Enable CPU power down bit in power control register
	 * ---------------------------------------------------
	 */
	mrs	x0, CORTEX_MAKALU_ELP_ARM_CPUPWRCTLR_EL1
	orr	x0, x0, #CORTEX_MAKALU_ELP_ARM_CPUPWRCTLR_EL1_CORE_PWRDN_BIT
	msr	CORTEX_MAKALU_ELP_ARM_CPUPWRCTLR_EL1, x0
	isb
	ret
endfunc cortex_makalu_elp_arm_core_pwr_dwn

func check_errata_cve_2022_23960
#if WORKAROUND_CVE_2022_23960
	mov	x0, #ERRATA_APPLIES
#else
	mov	x0, #ERRATA_MISSING
#endif
	ret
endfunc check_errata_cve_2022_23960

func cortex_makalu_elp_arm_reset_func
	/* Disable speculative loads */
	msr	SSBS, xzr

#if IMAGE_BL31 && WORKAROUND_CVE_2022_23960
	/*
	 * The Cortex Makalu ELP generic vectors are overridden to apply
	 * errata mitigation on exception entry from lower ELs.
         */
	adr	x0, wa_cve_vbar_cortex_makalu_elp_arm
	msr	vbar_el3, x0
#endif /* IMAGE_BL31 && WORKAROUND_CVE_2022_23960 */

	isb
	ret
endfunc cortex_makalu_elp_arm_reset_func

#if REPORT_ERRATA
/*
 * Errata printing function for Cortex Makalu ELP. Must follow AAPCS.
 */
func cortex_makalu_elp_arm_errata_report
	stp	x8, x30, [sp, #-16]!

	bl	cpu_get_rev_var
	mov	x8, x0

	/*
	 * Report all errata. The revision-variant information is passed to
	 * checking functions of each errata.
	 */
	report_errata WORKAROUND_CVE_2022_23960, cortex_makalu_elp_arm, cve_2022_23960

	ldp	x8, x30, [sp], #16
	ret
endfunc cortex_makalu_elp_arm_errata_report
#endif

	/* ---------------------------------------------
	 * This function provides Cortex Makalu ELP-
	 * specific register information for crash
	 * reporting. It needs to return with x6
	 * pointing to a list of register names in ascii
	 * and x8 - x15 having values of registers to be
	 * reported.
	 * ---------------------------------------------
	 */
.section .rodata.cortex_makalu_elp_arm_regs, "aS"
cortex_makalu_elp_arm_regs:  /* The ascii list of register names to be reported */
	.asciz	"cpuectlr_el1", ""

func cortex_makalu_elp_arm_cpu_reg_dump
	adr	x6, cortex_makalu_elp_arm_regs
	mrs	x8, CORTEX_MAKALU_ELP_ARM_CPUECTLR_EL1
	ret
endfunc cortex_makalu_elp_arm_cpu_reg_dump

declare_cpu_ops cortex_makalu_elp_arm, CORTEX_MAKALU_ELP_ARM_MIDR, \
	cortex_makalu_elp_arm_reset_func, \
	cortex_makalu_elp_arm_core_pwr_dwn