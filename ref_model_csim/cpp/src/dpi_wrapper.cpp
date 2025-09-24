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
 *  Description   : DPI wrapper of the C++ reference model functions
 *  History       :
 */

#include "operations.h"
#include "memory.h"
#include "dpiheader.h"
#include <stdio.h>

// Align RTL rounding mode with that of MPFR
// structure
mpfr_rnd_t rnd_rtl_to_c(int rnd_rtl) {
    mpfr_rnd_t rnd_c;
    if (rnd_rtl == 2)
    {
        rnd_c = MPFR_RNDD;
    }
    else if (rnd_rtl == 3) {
        rnd_c = MPFR_RNDU;
    }
    else if (rnd_rtl == 4) {
        rnd_c = MPFR_RNDNA;
    }
    else {
        rnd_c = static_cast<mpfr_rnd_t>(rnd_rtl);
    }
    return rnd_c;    
}

int dpi_fadd(svBitVecVal *result, const svBitVecVal *op1, const svBitVecVal *op2, int rounding_mode, const env_t* env)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    uint32_t* op2_cast  = const_cast<uint32_t*>(op2);
    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);
    
    int res = add(result, op1_cast, op2_cast, rnd_cast, env_c);
	
	return res;
}

int dpi_fsub(svBitVecVal *result, const svBitVecVal *op1, const svBitVecVal *op2, int rounding_mode, const env_t* env)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    uint32_t* op2_cast  = const_cast<uint32_t*>(op2);
    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);
    
    int res = sub(result, op1_cast, op2_cast, rnd_cast, env_c);
	
	return res;
}

int dpi_fmul(svBitVecVal *result, const svBitVecVal *op1, const svBitVecVal *op2, int rounding_mode, const env_t* env)
{
    environment env_c;

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    uint32_t* op2_cast  = const_cast<uint32_t*>(op2);
    
    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);
    
    // mpfr_rnd_t rnd_cast = static_cast<mpfr_rnd_t>(rounding_mode);
    
    int res = mul(result, op1_cast, op2_cast, rnd_cast, env_c);
	
	return res;
}

int dpi_fdiv(svBitVecVal *result, const svBitVecVal *op1, const svBitVecVal *op2, int rounding_mode, const env_t* env)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    uint32_t* op2_cast  = const_cast<uint32_t*>(op2);

    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);
    // mpfr_rnd_t rnd_cast = static_cast<mpfr_rnd_t>(rounding_mode);
    
    int res = div(result, op1_cast, op2_cast, rnd_cast, env_c);
	
	return res;
}

int dpi_fma(svBitVecVal *result, const svBitVecVal *op1, const svBitVecVal *op2, const svBitVecVal *op3, int rounding_mode, const env_t* env)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    uint32_t* op2_cast  = const_cast<uint32_t*>(op2);
    uint32_t* op3_cast  = const_cast<uint32_t*>(op3);

    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);

    int res = fma(result, op1_cast, op2_cast, op3_cast, rnd_cast, env_c);
	return res;
}

int dpi_fms(svBitVecVal *result, const svBitVecVal *op1, const svBitVecVal *op2, const svBitVecVal *op3, int rounding_mode, const env_t* env)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    uint32_t* op2_cast  = const_cast<uint32_t*>(op2);
    uint32_t* op3_cast  = const_cast<uint32_t*>(op3);

    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);
    
    int res = fms(result, op1_cast, op2_cast, op3_cast, rnd_cast, env_c);
	return res;
}

int dpi_fnma(svBitVecVal *result, const svBitVecVal *op1, const svBitVecVal *op2, const svBitVecVal *op3, int rounding_mode, const env_t* env)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    uint32_t* op2_cast  = const_cast<uint32_t*>(op2);
    uint32_t* op3_cast  = const_cast<uint32_t*>(op3);

    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);
    
    int res = fnma(result, op1_cast, op2_cast, op3_cast, rnd_cast, env_c);

    return res;
}

int dpi_fnms(svBitVecVal *result, const svBitVecVal *op1, const svBitVecVal *op2, const svBitVecVal *op3, int rounding_mode, const env_t* env)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    uint32_t* op2_cast  = const_cast<uint32_t*>(op2);
    uint32_t* op3_cast  = const_cast<uint32_t*>(op3);

    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);
    
    int res = fnms(result, op1_cast, op2_cast, op3_cast, rnd_cast, env_c);
    
    return res;
}

int dpi_fsqrt(svBitVecVal *result, const svBitVecVal *op, int rounding_mode, const env_t* env)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op_cast  = const_cast<uint32_t*>(op);
    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);
    
    int res = sqrt(result, op_cast, rnd_cast, env_c);    
	return res;
}

int dpi_fcmp(svBitVecVal* result, const svBitVecVal *op1, const svBitVecVal *op2, int rounding_mode, const env_t* env)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    uint32_t* op2_cast  = const_cast<uint32_t*>(op2);

    switch (rounding_mode)
    {
    case 0:
        return cmp_leq(result, op1_cast, op2_cast, env_c);
        break;
    case 1:
        return cmp_lt(result, op1_cast, op2_cast, env_c);
        break;    
    default:
        return cmp_eq(result, op1_cast, op2_cast, env_c);
        break;
    }
}

int dpi_fmin_max(svBitVecVal *result, const svBitVecVal *op1, const svBitVecVal *op2, int rounding_mode, const env_t* env)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    uint32_t* op2_cast  = const_cast<uint32_t*>(op2);
    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);

    switch (rounding_mode)
    {
    case 0:
        return fmin(result, op1_cast, op2_cast, rnd_cast, env_c);
        break;
    default:
        return fmax(result, op1_cast, op2_cast, rnd_cast, env_c);
        break;
    }
}

int dpi_fsgnj(svBitVecVal *result, const svBitVecVal *op1, const svBitVecVal *op2, int rounding_mode, const env_t* env)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    uint32_t* op2_cast  = const_cast<uint32_t*>(op2);
    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);
    
    return fsgnj(result, op1_cast, op2_cast, rnd_cast, env_c);
}

int dpi_fmv_f2x(svBitVecVal *result, const svBitVecVal *op1, const env_t* env, int nchunks)
{
    environment env_c;

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    
    return fmv_f2x(result, op1_cast, env_c, nchunks);
}
int dpi_fclass(svBitVecVal *result, const svBitVecVal *op1, const env_t* env)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);

    int res = fclass(result, op1_cast, env_c);
    return res;
}

int dpi_fcvt_f2i(svBitVecVal *result, const svBitVecVal *op1, int rounding_mode, const env_t* env, int is_signed, int int_format)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);

    switch (int_format)
    {
    case 1: // INT64
        return fcvt_f2i64(result, op1_cast, is_signed, rnd_cast, env_c);
        break;
    default: // INT32
        return fcvt_f2i32(result, op1_cast, is_signed, rnd_cast, env_c);
        break;
    }
}

int dpi_fcvt_i2f(svBitVecVal *result, const svBitVecVal *op1, int rounding_mode, const env_t* env, int is_signed, int int_format)
{
    environment env_c; 

    env_t* env_cast = const_cast<env_t*>(env);

    env_c.bis  = env_cast -> bis;
    env_c.es   = env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);
    
    return fcvt_i2f(result, op1_cast, is_signed, int_format, rnd_cast, env_c);
}

int dpi_fcvt_f2f(svBitVecVal *result, const svBitVecVal *op1, int rounding_mode, const env_t* src_env, const env_t* dst_env)
{
    environment src_env_c, dst_env_c; 

    env_t* src_env_cast = const_cast<env_t*>(src_env);
    env_t* dst_env_cast = const_cast<env_t*>(dst_env);

    src_env_c.bis  = src_env_cast -> bis;
    src_env_c.es   = src_env_cast -> es;

    dst_env_c.bis  = dst_env_cast -> bis;
    dst_env_c.es   = dst_env_cast -> es;

    uint32_t* op1_cast  = const_cast<uint32_t*>(op1);
    mpfr_rnd_t rnd_cast = rnd_rtl_to_c(rounding_mode);
    
    return fcvt_f2f(result, op1_cast, rnd_cast, src_env_c, dst_env_c);
}
