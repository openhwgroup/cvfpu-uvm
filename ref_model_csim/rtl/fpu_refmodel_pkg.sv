/*
 *  Copyright (c) 2025 CEA*
 *  *Commissariat a l'Energie Atomique et aux Energies Alternatives (CEA)
 *
 *  SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
 *
 *  Licensed under the Solderpad Hardware License v 2.1 (the “License”); you
 *  may not use this file except in compliance with the License, or, at your
 *  option, the Apache License version 2.0. You may obtain a copy of the
 *  License at
 *
 *  https://solderpad.org/licenses/SHL-2.1/
 *
 *  Unless required by applicable law or agreed to in writing, any work
 *  distributed under the License is distributed on an “AS IS” BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */
/*
 *  Authors       : Ihsane TAHIR
 *  Creation Date : March, 2025
 *  Description   : Package of CVFPU reference model containing DPI-C imports
 *  History       :
 */

package fpu_refmodel_pkg;

    // -----------------------------------------------------------
    // Type definitions for Reference Model
    // -----------------------------------------------------------
    typedef enum {
        MPFR_RNDN=0,  /* round to nearest, with ties to even */
        MPFR_RNDZ,    /* round toward zero */
        MPFR_RNDD,    /* round toward +Inf */
        MPFR_RNDU,   /* round toward -Inf */
        MPFR_RNDNA  /*round to nearest away from zero*/
    } mpfr_rnd_e;

    typedef struct {
        shortint bis; // Bit size of floating point number
        byte     es;  // Exponent size of floating point number
    } env_t;

  import "DPI-C" function int dpi_fadd(output bit [CVA6Cfg.FLen-1:0] result,
                                        input  bit [CVA6Cfg.XLEN-1:0] op1,
                                        input  bit [CVA6Cfg.XLEN-1:0] op2,
                                        input  mpfr_rnd_e             rounding_mode,
                                        input  env_t                  env);
  import "DPI-C" function int dpi_fsub(output bit [CVA6Cfg.FLen-1:0] result,
                                        input  bit [CVA6Cfg.XLEN-1:0] op1,
                                        input  bit [CVA6Cfg.XLEN-1:0] op2,
                                        input  mpfr_rnd_e             rounding_mode,
                                        input  env_t                  env);
  import "DPI-C" function int dpi_fmul(output bit [CVA6Cfg.FLen-1:0] result,
                                        input  bit [CVA6Cfg.XLEN-1:0] op1,
                                        input  bit [CVA6Cfg.XLEN-1:0] op2,
                                        input  mpfr_rnd_e             rounding_mode,
                                        input  env_t                  env);
  import "DPI-C" function int dpi_fdiv(output bit [CVA6Cfg.FLen-1:0] result,
                                        input  bit [CVA6Cfg.XLEN-1:0] op1,
                                        input  bit [CVA6Cfg.XLEN-1:0] op2,
                                        input  mpfr_rnd_e             rounding_mode,
                                        input  env_t                  env);
  import "DPI-C" function int dpi_fma(output bit [CVA6Cfg.FLen-1:0] result,
                                        input  bit [CVA6Cfg.XLEN-1:0] op1,
                                        input  bit [CVA6Cfg.XLEN-1:0] op2,
                                        input  bit [CVA6Cfg.XLEN-1:0] op3,
                                        input  mpfr_rnd_e             rounding_mode,
                                        input  env_t                  env);
  import "DPI-C" function int dpi_fnma(output bit [CVA6Cfg.FLen-1:0] result,
                                        input  bit [CVA6Cfg.XLEN-1:0] op1,
                                        input  bit [CVA6Cfg.XLEN-1:0] op2,
                                        input  bit [CVA6Cfg.XLEN-1:0] op3,
                                        input  mpfr_rnd_e             rounding_mode,
                                        input  env_t                  env);
  import "DPI-C" function int dpi_fms(output bit [CVA6Cfg.FLen-1:0] result,
                                        input  bit [CVA6Cfg.XLEN-1:0] op1,
                                        input  bit [CVA6Cfg.XLEN-1:0] op2,
                                        input  bit [CVA6Cfg.XLEN-1:0] op3,
                                        input  mpfr_rnd_e             rounding_mode,
                                        input  env_t                  env);
  import "DPI-C" function int dpi_fnms(output bit [CVA6Cfg.FLen-1:0] result,
                                        input  bit [CVA6Cfg.XLEN-1:0] op1,
                                        input  bit [CVA6Cfg.XLEN-1:0] op2,
                                        input  bit [CVA6Cfg.XLEN-1:0] op3,
                                        input  mpfr_rnd_e             rounding_mode,
                                        input  env_t                  env);
  import "DPI-C" function int dpi_fsqrt(output bit [CVA6Cfg.FLen-1:0] result,
                                        input  bit [CVA6Cfg.XLEN-1:0] op,
                                        input  mpfr_rnd_e             rounding_mode,
                                        input  env_t                  env);
  import "DPI-C" function int dpi_fcmp( output bit [CVA6Cfg.FLen-1:0] result,
										                    input  bit [CVA6Cfg.XLEN-1:0] op1,
                                        input  bit [CVA6Cfg.XLEN-1:0] op2,
                                        input  mpfr_rnd_e             rounding_mode,
                                        input  env_t                  env);
  import "DPI-C" function int dpi_fmin_max(output bit [CVA6Cfg.FLen-1:0] result,
                                           input  bit [CVA6Cfg.XLEN-1:0] op1,
                                           input  bit [CVA6Cfg.XLEN-1:0] op2,
                                           input  mpfr_rnd_e             rounding_mode,
                                           input  env_t                  env);
  import "DPI-C" function int dpi_fsgnj(output bit [CVA6Cfg.FLen-1:0] result,
                                           input  bit [CVA6Cfg.XLEN-1:0] op1,
                                           input  bit [CVA6Cfg.XLEN-1:0] op2,
                                           input  mpfr_rnd_e             rounding_mode,
                                           input  env_t                  env);
  import "DPI-C" function int dpi_fmv_f2x(output bit [CVA6Cfg.FLen-1:0] result,
                                           input  bit [CVA6Cfg.XLEN-1:0] op1,
                                           input  env_t                  env,
                                           input  int                    nchunks);
  import "DPI-C" function int dpi_fclass(output bit [CVA6Cfg.FLen-1:0] result,
                                           input  bit [CVA6Cfg.XLEN-1:0] op1,
                                           input  env_t                  env);                                           
  import "DPI-C" function int dpi_fcvt_f2i(output bit [CVA6Cfg.FLen-1:0] result,
                                           input  bit [CVA6Cfg.XLEN-1:0] op1,
                                           input  mpfr_rnd_e             rounding_mode,
                                           input  env_t                  env,
                                           input  int                    is_signed,
                                           input  int                    int_format);
  import "DPI-C" function int dpi_fcvt_i2f(output bit [CVA6Cfg.FLen-1:0] result,
                                           input  bit [CVA6Cfg.XLEN-1:0] op1,
                                           input  mpfr_rnd_e             rounding_mode,
                                           input  env_t                  env,
                                           input  int                    is_signed,
                                           input  int                    int_format);
  import "DPI-C" function int dpi_fcvt_f2f(output bit [CVA6Cfg.FLen-1:0] result,
                                           input  bit [CVA6Cfg.XLEN-1:0]  op1,
                                           input  mpfr_rnd_e             rounding_mode,
                                           input  env_t                  src_env,
                                           input  env_t                  dst_env);
  import uvm_pkg::*;
  import fpu_common_pkg::*;
  import ariane_pkg::*;

  `include "uvm_macros.svh"
  `include "fpu_refmodel.svh"
    
endpackage