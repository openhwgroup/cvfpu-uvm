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
 *  Description   : Contains functions that compute floating point operations
 *  History       :
 */


#include <stdio.h>
#include <stdarg.h>
#include <gmp.h>
#include <mpfr.h>
#include <iostream>
#include <cstdint>
#include <algorithm>//for std::min() and std::max()
#include "bitwise.h"
#include "operations.h"
#include "memory.h"

int add(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env)
{
    mpfr_t op1_mpfr, op2_mpfr, result_mpfr;

    IEEElike_set_exp_range(env.es, MBITS(env));

    IEEElike2mpfr(op1_mpfr, op1, env, rounding_mode, 0, false);
    IEEElike2mpfr(op2_mpfr, op2, env, rounding_mode, 0, false);
	
	bool sNaN_inputs = IEEElike_is_sNaN(op1, env) || IEEElike_is_sNaN(op2, env);
	bool qNaN_inputs = IEEElike_is_qNaN(op1, env) || IEEElike_is_qNaN(op2, env);

	mpfr_init2(result_mpfr, MBITS(env)+1);

    mpfr_clear_flags ();
    
    //MPFR operation
    int i = mpfr_add(result_mpfr,op1_mpfr,op2_mpfr,rounding_mode);    
	i = mpfr_subnormalize(result_mpfr, i, rounding_mode);

    mpfr2IEEElike(result, result_mpfr, env, rounding_mode, false);
	
	// Exception flags
	int res = get_flags(sNaN_inputs, qNaN_inputs);
	
	return res;
}

int sub(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env)
{
    mpfr_t op1_mpfr, op2_mpfr, result_mpfr;

    // Set subnormalized exponent range
    IEEElike_set_exp_range(env.es, MBITS(env));

    IEEElike2mpfr(op1_mpfr, op1, env, rounding_mode, 0, false);
    IEEElike2mpfr(op2_mpfr, op2, env, rounding_mode, 0, false);
	
	bool sNaN_inputs = IEEElike_is_sNaN(op1, env) || IEEElike_is_sNaN(op2, env);
	bool qNaN_inputs = IEEElike_is_qNaN(op1, env) || IEEElike_is_qNaN(op2, env);

    mpfr_init2(result_mpfr, MBITS(env)+1);
    mpfr_clear_flags ();

    //MPFR operation
    int i = mpfr_sub(result_mpfr,op1_mpfr,op2_mpfr,rounding_mode);
    i = mpfr_subnormalize(result_mpfr, i, rounding_mode);

    mpfr2IEEElike(result, result_mpfr, env, rounding_mode, false);
	
	// Exception flags
	int res = get_flags(sNaN_inputs, qNaN_inputs);
	
	return res;
}

int mul(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env)
{    
    mpfr_t op1_mpfr, op2_mpfr, result_mpfr;
	
    IEEElike_set_exp_range(env.es, MBITS(env));

    IEEElike2mpfr(op1_mpfr, op1, env, rounding_mode, 0, false);
    IEEElike2mpfr(op2_mpfr, op2, env, rounding_mode, 0, false);
	
    bool sNaN_inputs = IEEElike_is_sNaN(op1, env) || IEEElike_is_sNaN(op2, env);
	bool qNaN_inputs = IEEElike_is_qNaN(op1, env) || IEEElike_is_qNaN(op2, env);

	mpfr_init2(result_mpfr, MBITS(env)+1);

    mpfr_clear_flags ();
	
    //MPFR operation
    int i = mpfr_mul(result_mpfr,op1_mpfr,op2_mpfr,rounding_mode);
	i = mpfr_subnormalize(result_mpfr, i, rounding_mode);
   
    mpfr2IEEElike(result, result_mpfr, env, rounding_mode, false);
	
	// Exception flags
	int res = get_flags(sNaN_inputs, qNaN_inputs);
	
	return res;
}

int div(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env)
{
    mpfr_t op1_mpfr, op2_mpfr, result_mpfr;

    IEEElike_set_exp_range(env.es, MBITS(env));

    IEEElike2mpfr(op1_mpfr, op1, env, rounding_mode, 0, false);
    IEEElike2mpfr(op2_mpfr, op2, env, rounding_mode, 0, false);
	
    bool sNaN_inputs = IEEElike_is_sNaN(op1, env) || IEEElike_is_sNaN(op2, env);
	bool qNaN_inputs = IEEElike_is_qNaN(op1, env) || IEEElike_is_qNaN(op2, env);

	mpfr_init2(result_mpfr, MBITS(env)+1);	
    mpfr_clear_flags ();

    //MPFR operation
    int i = mpfr_div(result_mpfr,op1_mpfr,op2_mpfr,rounding_mode);
	i = mpfr_subnormalize(result_mpfr, i, rounding_mode);

    mpfr2IEEElike(result, result_mpfr, env, rounding_mode, false);
	
	// Exception flags
	int res = get_flags(sNaN_inputs, qNaN_inputs);
	return res;
}

int sqrt(uint32_t* result, const uint32_t* op, mpfr_rnd_t rounding_mode, environment env)
{
    mpfr_t op_mpfr, result_mpfr;

    // Set exponent range
    IEEElike_set_exp_range(env.es, MBITS(env));

    IEEElike2mpfr(op_mpfr, op, env, rounding_mode, 0, false);
	
    mpfr_init2(result_mpfr, MBITS(env)+1);
	
	bool sNaN_inputs = IEEElike_is_sNaN(op, env);
	bool qNaN_inputs = IEEElike_is_qNaN(op, env);
	
    mpfr_clear_flags ();

    int i = mpfr_sqrt(result_mpfr, op_mpfr, rounding_mode);
    i =  mpfr_subnormalize(result_mpfr, i, rounding_mode);
    
    mpfr2IEEElike(result, result_mpfr, env, rounding_mode, false);
	
	int res = get_flags(sNaN_inputs, qNaN_inputs);
	
	return res;
}

int fma(uint32_t* result, const uint32_t* op1, const uint32_t* op2, const uint32_t* op3, mpfr_rnd_t rounding_mode, environment env)
{
    mpfr_t op1_mpfr, op2_mpfr, op3_mpfr, result_mpfr;
    IEEElike_set_exp_range(env.es, MBITS(env));

    IEEElike2mpfr(op1_mpfr, op1, env, rounding_mode, 0, false);
    IEEElike2mpfr(op2_mpfr, op2, env, rounding_mode, 0, false);
    IEEElike2mpfr(op3_mpfr, op3, env, rounding_mode, 0, false);
    
	bool sNaN_inputs = IEEElike_is_sNaN(op1, env) || IEEElike_is_sNaN(op2, env) || IEEElike_is_sNaN(op3, env);
	bool qNaN_inputs = IEEElike_is_qNaN(op1, env) || IEEElike_is_qNaN(op2, env) || IEEElike_is_qNaN(op3, env);

    mpfr_init2(result_mpfr, MBITS(env)+1);
    
    mpfr_clear_flags ();

	//MPFR operation
    int i = mpfr_fma(result_mpfr,op1_mpfr,op2_mpfr,op3_mpfr,rounding_mode);
	i = mpfr_subnormalize(result_mpfr, i, rounding_mode);

    mpfr2IEEElike(result, result_mpfr, env, rounding_mode, false);
	
	// Exception flags
	// 0 x INF + qNaN generates invalid operation (NV) exception
	int special_op = ((IEEElike_is_Zero(op1,env) && IEEElike_is_Inf(op2,env)) || (IEEElike_is_Zero(op2,env) && IEEElike_is_Inf(op1,env))) && IEEElike_is_qNaN(op3, env);
					
	int res = special_op ? 16 : get_flags(sNaN_inputs, qNaN_inputs);
	
	return res;

}

int fnma(uint32_t* result, const uint32_t* op1, const uint32_t* op2, const uint32_t* op3, mpfr_rnd_t rounding_mode, environment env)
{
    mpfr_t op1_mpfr, op2_mpfr, op3_mpfr, res_mpfr, final_res_mpfr;
    int inex;

    // Initialize working environment
    int wp = abs(IEEElike_emax(env.es) - IEEElike_emin(env.es)); // Working precision

    mpfr_set_emin(MPFR_EMIN_MIN);
    mpfr_set_emax(MPFR_EMAX_MAX);

    IEEElike2mpfr(op1_mpfr, op1, env, rounding_mode, 0, false);
    IEEElike2mpfr(op2_mpfr, op2, env, rounding_mode, 0, false);
    IEEElike2mpfr(op3_mpfr, op3, env, rounding_mode, 0, false);
    
	mpfr_init2(res_mpfr, wp+1);
	mpfr_init2(final_res_mpfr, MBITS(env)+1);

    mpfr_clear_flags ();
	
	bool sNaN_inputs = IEEElike_is_sNaN(op1, env) || IEEElike_is_sNaN(op2, env) || IEEElike_is_sNaN(op3, env);
	bool qNaN_inputs = IEEElike_is_qNaN(op1, env) || IEEElike_is_qNaN(op2, env) || IEEElike_is_qNaN(op3, env);
    
	// res = -op1*op2 + op3
    mpfr_mul(res_mpfr, op1_mpfr, op2_mpfr, rounding_mode);
	mpfr_neg(res_mpfr, res_mpfr, rounding_mode);       
	inex = mpfr_sub(final_res_mpfr, res_mpfr, op3_mpfr, rounding_mode);  

    IEEElike_set_exp_range(env.es, MBITS(env));

    mpfr_check_range(final_res_mpfr, inex, rounding_mode);
    inex = mpfr_subnormalize(final_res_mpfr, inex, rounding_mode);

    mpfr2IEEElike(result, final_res_mpfr, env, rounding_mode, false);
    
	// Exception flags
	// 0 x INF - qNaN generates invalid operation (NV) exception
	int special_op = ((IEEElike_is_Zero(op1,env) && IEEElike_is_Inf(op2,env)) || (IEEElike_is_Zero(op2,env) && IEEElike_is_Inf(op1,env))) && IEEElike_is_qNaN(op3, env);
					
	int res = special_op ? 16 : get_flags(sNaN_inputs, qNaN_inputs);

	return res;
}

int fms(uint32_t* result, const uint32_t* op1, const uint32_t* op2, const uint32_t* op3, mpfr_rnd_t rounding_mode, environment env)
{
    mpfr_t op1_mpfr, op2_mpfr, op3_mpfr, result_mpfr;

    IEEElike_set_exp_range(env.es, MBITS(env));

    IEEElike2mpfr(op1_mpfr, op1, env, rounding_mode, 0, false);
    IEEElike2mpfr(op2_mpfr, op2, env, rounding_mode, 0, false);
    IEEElike2mpfr(op3_mpfr, op3, env, rounding_mode, 0, false);
    
    mpfr_init2(result_mpfr, MBITS(env)+1);
	
	bool sNaN_inputs = IEEElike_is_sNaN(op1, env) || IEEElike_is_sNaN(op2, env) || IEEElike_is_sNaN(op3, env);
	bool qNaN_inputs = IEEElike_is_qNaN(op1, env) || IEEElike_is_qNaN(op2, env) || IEEElike_is_qNaN(op3, env);

	mpfr_clear_flags ();

    //MPFR operation
    int i = mpfr_fms(result_mpfr,op1_mpfr,op2_mpfr,op3_mpfr,rounding_mode);
	i = mpfr_subnormalize(result_mpfr, i, rounding_mode);

    mpfr2IEEElike(result, result_mpfr, env, rounding_mode, false);

	// Exception flags
	// 0 x INF - qNaN generates invalid operation (NV) exception
	int special_op = ((IEEElike_is_Zero(op1,env) && IEEElike_is_Inf(op2,env)) || (IEEElike_is_Zero(op2,env) && IEEElike_is_Inf(op1,env))) && IEEElike_is_qNaN(op3, env);
					
	int res = special_op ? 16 : get_flags(sNaN_inputs, qNaN_inputs);
	
	return res;
}

int fnms(uint32_t* result, const uint32_t* op1, const uint32_t* op2, const uint32_t* op3, mpfr_rnd_t rounding_mode, environment env)
{
    mpfr_t op1_mpfr, op2_mpfr, op3_mpfr, res_mpfr, final_res_mpfr;
    int inex;

    // Initialize working environment
    int wp = abs(IEEElike_emax(env.es) - IEEElike_emin(env.es)); // Working precision

    mpfr_set_emin(MPFR_EMIN_MIN);
    mpfr_set_emax(MPFR_EMAX_MAX);

    IEEElike2mpfr(op1_mpfr, op1, env, rounding_mode, 0, false);
    IEEElike2mpfr(op2_mpfr, op2, env, rounding_mode, 0, false);
    IEEElike2mpfr(op3_mpfr, op3, env, rounding_mode, 0, false);
    
	mpfr_init2(res_mpfr, wp+1);
	mpfr_init2(final_res_mpfr, MBITS(env)+1);

    mpfr_clear_flags ();
	
	bool sNaN_inputs = IEEElike_is_sNaN(op1, env) || IEEElike_is_sNaN(op2, env) || IEEElike_is_sNaN(op3, env);
	bool qNaN_inputs = IEEElike_is_qNaN(op1, env) || IEEElike_is_qNaN(op2, env) || IEEElike_is_qNaN(op3, env);
    
	// res = -op1*op2 + op3
    mpfr_mul(res_mpfr, op1_mpfr, op2_mpfr, rounding_mode);
	mpfr_neg(res_mpfr, res_mpfr, rounding_mode);       
	inex = mpfr_add(final_res_mpfr, res_mpfr, op3_mpfr, rounding_mode);  

    IEEElike_set_exp_range(env.es, MBITS(env));

    mpfr_check_range(final_res_mpfr, inex, rounding_mode);
    inex = mpfr_subnormalize(final_res_mpfr, inex, rounding_mode);

    // inex = mpfr_prec_round(final_res_mpfr, MBITS(env)+1, rounding_mode);

    mpfr2IEEElike(result, final_res_mpfr, env, rounding_mode, false);
    
	// Exception flags
	// 0 x INF - qNaN generates invalid operation (NV) exception
	int special_op = ((IEEElike_is_Zero(op1,env) && IEEElike_is_Inf(op2,env)) || (IEEElike_is_Zero(op2,env) && IEEElike_is_Inf(op1,env))) && IEEElike_is_qNaN(op3, env);
					
	int res = special_op ? 16 : get_flags(sNaN_inputs, qNaN_inputs);

	return res;
}

int cmp_leq(uint32_t* result, const uint32_t* op1, const uint32_t* op2, environment env, bool print_details)
{
    int flags = 0;
    
    IEEElike_set_exp_range(env.es, MBITS(env));
	
    mpfr_t op1_mpfr, op2_mpfr;
    
	IEEElike2mpfr(op1_mpfr, op1, env, MPFR_RNDN, 0, false);
    IEEElike2mpfr(op2_mpfr, op2, env, MPFR_RNDN, 0, false);
	
	bool sNaN_inputs = IEEElike_is_sNaN(op1, env) || IEEElike_is_sNaN(op2, env);
	bool qNaN_inputs = IEEElike_is_qNaN(op1, env) || IEEElike_is_qNaN(op2, env);

    if(print_details) { mpfr_printf("First MPFR operand is %RNf\nSecond MPFR operand is %RNf\n",op1_mpfr,op2_mpfr); }
    *result = (mpfr_lessequal_p(op1_mpfr,op2_mpfr)!=0);
    if(print_details) { printf("result : %s\n",result ? "true, lesser or equal" : "false, greater than"); }

    mpfr_clear(op1_mpfr);
    mpfr_clear(op2_mpfr);
	
	// Exception flags
	if (sNaN_inputs || qNaN_inputs) SET_BIT_TO_1__DWORD(flags, 4);
	
    return flags;
}

int cmp_lt(uint32_t* result, const uint32_t* op1, const uint32_t* op2, environment env, bool print_details)
{
	int flags = 0;

    IEEElike_set_exp_range(env.es, MBITS(env));

	mpfr_t op1_mpfr, op2_mpfr;

    IEEElike2mpfr(op1_mpfr, op1, env, MPFR_RNDN, 0, false);
    IEEElike2mpfr(op2_mpfr, op2, env, MPFR_RNDN, 0, false);
	
	bool sNaN_inputs = IEEElike_is_sNaN(op1, env) || IEEElike_is_sNaN(op2, env);
	bool qNaN_inputs = IEEElike_is_qNaN(op1, env) || IEEElike_is_qNaN(op2, env);

    if(print_details) { mpfr_printf("First MPFR operand is %RNf\nSecond MPFR operand is %RNf\n",op1_mpfr,op2_mpfr); }
    *result = (mpfr_less_p(op1_mpfr,op2_mpfr)!=0);
    if(print_details) { printf("result : %s\n",result ? "true, lesser than" : "false, greater or equal"); }
    mpfr_clear(op1_mpfr);
    mpfr_clear(op2_mpfr);
	
	// Exception flags
	if (sNaN_inputs || qNaN_inputs) SET_BIT_TO_1__DWORD(flags, 4);

	return flags;
}

int cmp_eq(uint32_t* result, const uint32_t* op1, const uint32_t* op2, environment env, bool print_details)
{
	int flags = 0;

    IEEElike_set_exp_range(env.es, MBITS(env));

    mpfr_t op1_mpfr, op2_mpfr;

    IEEElike2mpfr(op1_mpfr, op1, env, MPFR_RNDN, 0, false);
    IEEElike2mpfr(op2_mpfr, op2, env, MPFR_RNDN, 0, false);
	
	bool sNaN_inputs = IEEElike_is_sNaN(op1, env) || IEEElike_is_sNaN(op2, env);

	if(print_details) { mpfr_printf("First MPFR operand is %.20RNf\nSecond MPFR operand is %.20RNf\n",op1_mpfr,op2_mpfr); }
    *result = (mpfr_equal_p(op1_mpfr,op2_mpfr)!=0);
    if(print_details) { printf("result : %s\n",result ? "true, equal" : "false, not equal"); }
    mpfr_clear(op1_mpfr);
    mpfr_clear(op2_mpfr);
    
	// Exception flags
	if (sNaN_inputs) SET_BIT_TO_1__DWORD(flags, 4);

	return flags;
}

int fmin(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env)
{
	int flags = 0;

    IEEElike_set_exp_range(env.es, MBITS(env));
	mpfr_t op1_mpfr, op2_mpfr, result_mpfr;

    IEEElike2mpfr(op1_mpfr, op1, env, rounding_mode, 0, false);
    IEEElike2mpfr(op2_mpfr, op2, env, rounding_mode, 0, false);
	
	bool sNaN_inputs = IEEElike_is_sNaN(op1, env) || IEEElike_is_sNaN(op2, env);

    mpfr_init2(result_mpfr, MBITS(env)+1);

    //MPFR operation
    mpfr_min(result_mpfr,op1_mpfr,op2_mpfr,rounding_mode);

    mpfr2IEEElike(result, result_mpfr, env, rounding_mode, false);
	
	// Exception flags
	if (sNaN_inputs) SET_BIT_TO_1__DWORD(flags, 4);

	return flags;
}

int fmax(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env)
{
	int flags = 0;
    IEEElike_set_exp_range(env.es, MBITS(env));

	mpfr_t op1_mpfr, op2_mpfr, result_mpfr;

    IEEElike2mpfr(op1_mpfr, op1, env, rounding_mode, 0, false);
    IEEElike2mpfr(op2_mpfr, op2, env, rounding_mode, 0, false);
    
    mpfr_init2(result_mpfr, MBITS(env)+1);

	bool sNaN_inputs = IEEElike_is_sNaN(op1, env) || IEEElike_is_sNaN(op2, env);

    //MPFR operation
    mpfr_max(result_mpfr,op1_mpfr,op2_mpfr,rounding_mode);

    mpfr2IEEElike(result, result_mpfr, env, rounding_mode, false);
	
	// Exception flags
	if (sNaN_inputs) SET_BIT_TO_1__DWORD(flags, 4);

	return flags;
}

int fcvt_f2i32 (uint32_t* result, const uint32_t* op1, int is_signed, mpfr_rnd_t rounding_mode, environment env)
{
    int exception;
	mpfr_t op1_mpfr, mpfr_max, mpfr_min;
    mpfr_prec_t prec;
    int s;
    mpfr_t x;
    IEEElike_set_exp_range(env.es, MBITS(env));

    int64_t temp_result;
    int32_t res32;

    IEEElike2mpfr(op1_mpfr, op1, env, rounding_mode, 0, false);
    mpfr_inits2(64, mpfr_min, mpfr_max, NULL);

    for (s = INT32_MAX, prec = 0; s != 0; s /= 2, prec++)
    { }
    
    // Set integer bounds 
    if (is_signed) {
        mpfr_clear_flags();
        mpfr_init2 (x, prec);
        mpfr_rint (x, op1_mpfr, rounding_mode);

        if (!mpfr_fits_sint_p(op1_mpfr, rounding_mode)) {
            res32 = (mpfr_sgn(op1_mpfr)<0) ? INT32_MIN : INT32_MAX;
            exception   = 16;
        } else
        {
    		res32 = mpfr_get_si(op1_mpfr, rounding_mode);
            exception = get_conv_flags();
        }
    } else {
        mpfr_clear_flags();
        if (!mpfr_fits_uint_p(op1_mpfr, rounding_mode)) {
            res32 = (mpfr_sgn(op1_mpfr)<0) ? 0 : UINT32_MAX;
            exception   = 16;
        } else
        {
    		res32 = mpfr_get_ui(op1_mpfr, rounding_mode);
            exception = get_conv_flags();
        }
    }
    
    if (mpfr_nan_p(op1_mpfr)) {
        res32 = is_signed ? INT32_MAX : UINT32_MAX;
        exception   = 16;
    }
    // Sign extend
    temp_result = int64_t(res32);
	
    result[0] = temp_result & 0xFFFFFFFF;
    result[1] = (temp_result >> 32) & 0xFFFFFFFF;	

	return exception;
}

int fcvt_f2i64(uint32_t* result, const uint32_t* op1, int is_signed, mpfr_rnd_t rounding_mode, environment env)
{
    mpfr_t op1_mpfr, mpfr_max, mpfr_min;
    uint64_t temp_result;
	int exception;

    IEEElike_set_exp_range(env.es, MBITS(env));

    IEEElike2mpfr(op1_mpfr, op1, env, rounding_mode, 0, false);
    mpfr_inits2(64, mpfr_min, mpfr_max, NULL);
	
    if (is_signed) {
        mpfr_clear_flags();
		temp_result = mpfr_get_si(op1_mpfr, rounding_mode);
    } else {
        mpfr_clear_flags();
		temp_result = mpfr_get_ui(op1_mpfr, rounding_mode);		
    }
	
	exception = get_conv_flags();
    if (mpfr_nan_p(op1_mpfr)) {
        temp_result = is_signed ? INT64_MAX : UINT64_MAX;
    }

    result[0] = temp_result & ((1UL <<32) -1);
    result[1] = (temp_result >> 32) & ((1UL <<32) -1);
	
	return exception;
}

int fcvt_i2f(uint32_t* result, const uint32_t* op1, int is_signed, int int_format, mpfr_rnd_t rounding_mode, environment env)
{
    mpfr_t result_mpfr;
	int exception;

    IEEElike_set_exp_range(env.es, MBITS(env));

    mpfr_init2(result_mpfr, MBITS(env)+1);

    switch (int_format)
    {
    case 1: // INT64
		mpfr_clear_flags();
        if (is_signed)
        {
            int64_t val = *(const int64_t*)op1;
            mpfr_set_si(result_mpfr, val, rounding_mode);
        } else {
            uint64_t val = *(const uint64_t*)op1;
            mpfr_set_ui(result_mpfr, val, rounding_mode);
        }
        break;
    default: // INT32
		mpfr_clear_flags();
        if (is_signed)
        {
            int32_t val = *(const int32_t*)op1;
            mpfr_set_si(result_mpfr, val, rounding_mode);
        } else {
            uint32_t val = *(const uint32_t*)op1;
            mpfr_set_ui(result_mpfr, val, rounding_mode);
        }
        break;
    }
	exception = get_conv_flags();

    mpfr2IEEElike(result, result_mpfr, env, rounding_mode, false);
	return exception;
}

int fcvt_f2f(uint32_t* result, const uint32_t* op1, mpfr_rnd_t rounding_mode, environment src_env, environment dst_env)
{
    mpfr_t op1_mpfr;
	int exception;

    IEEElike_set_exp_range(src_env.es, MBITS(src_env));
	
	bool sNaN_inputs = IEEElike_is_sNaN(op1, src_env);
	bool qNaN_inputs = IEEElike_is_qNaN(op1, src_env);

    IEEElike2mpfr(op1_mpfr, op1, src_env, rounding_mode, 0, false);
	mpfr_clear_flags();

    //apply rounding
    int inex = mpfr_prec_round(op1_mpfr,(MBITS(dst_env)+1),rounding_mode);
	
	// Change exponent range to destination format
	IEEElike_set_exp_range(dst_env.es, MBITS(dst_env));
    mpfr_check_range(op1_mpfr, inex, rounding_mode);
	inex = mpfr_subnormalize(op1_mpfr, inex, rounding_mode);

    mpfr2IEEElike(result, op1_mpfr, dst_env, rounding_mode, false);
	
	exception = get_flags(sNaN_inputs, qNaN_inputs);
	return exception;
}

int fsgnj(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env)
{
    int    sign;

	result[0] = op1[0];
	result[1] = op1[1];

    switch (rounding_mode)
    {
    case MPFR_RNDN:
		sign = IEEElike_get_S(op2, env.es, MBITS(env));
        break;
    case MPFR_RNDZ:
		sign = !IEEElike_get_S(op2, env.es, MBITS(env));
        break;
    case MPFR_RNDD:
		sign = IEEElike_get_S(op1, env.es, MBITS(env)) xor IEEElike_get_S(op2, env.es, MBITS(env));
        break;
    default: // round up
		sign = IEEElike_get_S(op1, env.es, MBITS(env));
        break;
    }
	// Set sign
	if (sign) 
	{
		SET_BIT_TO_1__DWORD_ARRAY(result, IEEELIKE_S_INDEX(MBITS(env), env.es));//S set to 1
	} else 
	{
		SET_BIT_TO_0__DWORD_ARRAY(result, IEEELIKE_S_INDEX(MBITS(env), env.es));//S set to 1
	}
    return 0;
}

int fmv_f2x (uint32_t* result, const uint32_t* op1, environment env, int nchunks)
{   
    for (int i = 0; i < nchunks; i++)
    {
        if (env.bis == 63) {
            result[i] = op1[i];
        } else {
            result[i] = (i == 0)                              ? op1[i]     : 
                        IEEElike_get_S(op1,env.es,MBITS(env)) ? 0xFFFFFFFF :
                                                                0x0;
        }
    }
    return 0;
}

int fclass(uint32_t* result, const uint32_t* input_IEEElike, environment env, bool print_details)
{

    if (print_details) { printf("IEEE-like input = "); IEEElike_print_value(input_IEEElike,env); putchar('\n'); }

    uint16_t ms = MS(env);//number of explicit bits for the significand

    //check if T is 0
    bool T_is_null = IEEElike_T_is_null(input_IEEElike,env);
    
    //get E value
    uint64_t E = IEEElike_get_E(input_IEEElike,env.es,ms);

    //compute E_max
    uint64_t E_max = IEEElike_E_max(env.es);

    //get sign
    bool sign_bit = IEEElike_get_S(input_IEEElike,env.es,ms);

    result[0] = 0x0;

    if(IEEELIKE_IS_ZERO(E,T_is_null))//case +/- 0
    {
        if (sign_bit) // -0
        {
            SET_BIT_TO_1__DWORD_ARRAY(result, 3);
            if (print_details) {printf("-0\n");}
        } else // +0
        {
            SET_BIT_TO_1__DWORD_ARRAY(result, 4);
            if (print_details) {printf("+0\n");}
        }
    }
    else if(IEEELIKE_IS_INF(E,E_max,T_is_null))//case +/- inf
    {
        if (sign_bit) // -Inf
        {
            SET_BIT_TO_1__DWORD_ARRAY(result, 0);
            if (print_details) {printf("-Inf\n");}
        } else // +Inf
        {
            SET_BIT_TO_1__DWORD_ARRAY(result, 7);
            if (print_details) {printf("+Inf\n");}
        }
    }
    else if(IEEELIKE_IS_NAN(E,E_max,T_is_null))//case NaN
    {
        //MSB of T determines if it is a quiet NaN of a signaling one
        if(GET_BIT__DWORD_ARRAY(input_IEEElike,IEEELIKE_T_MSB_INDEX(ms))) 
        { 
            SET_BIT_TO_1__DWORD_ARRAY(result, 9);
            if (print_details) {printf("quiet NaN\n");} //MSB of T is 1 -> quiet NaN
        } else
        {
            SET_BIT_TO_1__DWORD_ARRAY(result, 8);
            if (print_details) {printf("signaling NaN\n");}  //MSB of T is 0 -> signaling NaN
        }
    }
    else if(IEEELIKE_IS_DENORMAL_NUMBER(E,T_is_null))//case denormal number
    {
        if (sign_bit)
        {
            SET_BIT_TO_1__DWORD_ARRAY(result, 2);
            if (print_details) {printf("Negative subnormal\n");}
        } else // +Inf
        {
            SET_BIT_TO_1__DWORD_ARRAY(result, 5);
            if (print_details) {printf("Positive subnormal\n");}
        }
    }
    else//case normal number
    {
        if (sign_bit)
        {
            SET_BIT_TO_1__DWORD_ARRAY(result, 1);
            if (print_details) {printf("Negative normal number\n");}
        } else
        {
            SET_BIT_TO_1__DWORD_ARRAY(result, 6);
            if (print_details) {printf("Positive normal number\n"); }
        }
    }
    return 0;
}

