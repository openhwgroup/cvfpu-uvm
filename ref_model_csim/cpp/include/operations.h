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
 *  Authors       : Sebastien Mestrallet, Ihsane TAHIR
 *  Creation Date : March, 2025
 *  Description   : Declare functions relative to floating point operations
 *  History       :
 */

#ifndef OPERATIONS_H_INCLUDED
#define OPERATIONS_H_INCLUDED

#include <stdio.h>
#include <stdarg.h>
#include <gmp.h>
#include <mpfr.h>
#include <iostream>
#include <cstdint>
#include "memory.h"

//########## ARITHMETIC OPERATORS ######################################################################################

/**
 * \brief   Addition of two floatin gpoint numbers
 * \details Convert the operands from floating point to MPFR variable, then use the addition function of MPFR, then convert the result as floating point
 *          
 * \param   result              Output variable. Where to write the addition result converted to floating point. Enough memory allocation should be done before.
 * \param   op1                 First operand of the addition.
 * \param   op2                 Second operand of the addition.
 * \param   rounding_mode       The rounding mode to be used. See MPFR documentation.
 * \param   working_precision   Max number of explicit bits used to store the significand of the result, minus one (one-biased)
 */
int add(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env);

/**
 * \brief   Substraction of two floatin gpoint numbers (op1-op2)
 * \details Convert the operands from floating point to MPFR variable, then use the substraction function of MPFR, then convert the result as floating point
 *          
 * \param   result          Output variable. Where to write the substraction result converted to floating point. Enough memory allocation should be done before.
 * \param   op1             First operand of the substraction.
 * \param   op2             Second operand of the substraction.
 * \param   rounding_mode   The rounding mode to be used. See MPFR documentation.
 * \param   working_precision   Max number of explicit bits used to store the significand of the result, minus one (one-biased)
 */
int sub(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env);

/**
 * \brief   Multiplication of two floatin gpoint numbers
 * \details Convert the operands from floating point to MPFR variable, then use the multiplication function of MPFR, then convert the result as floating point
 *          
 * \param   result          Output variable. Where to write the multiplication result converted to floating point. Enough memory allocation should be done before.
 * \param   op1             First operand of the multiplication.
 * \param   op2             Second operand of the multiplication.
 * \param   rounding_mode   The rounding mode to be used. See MPFR documentation.
 * \param   working_precision   Max number of explicit bits used to store the significand of the result, minus one (one-biased)
 */
int mul(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env);

/// @brief 
/// @param result 
/// @param op1 
/// @param op2 
/// @param rounding_mode 
/// @param env 
int div(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env);

int fma(uint32_t* result, const uint32_t* op1, const uint32_t* op2, const uint32_t* op3, mpfr_rnd_t rounding_mode, environment env);
/// @brief 
/// @param result 
/// @param op1 
/// @param op2 
/// @param op3 
/// @param rounding_mode 
/// @param env 
int fms(uint32_t* result, const uint32_t* op1, const uint32_t* op2, const uint32_t* op3, mpfr_rnd_t rounding_mode, environment env);

int fnma(uint32_t* result, const uint32_t* op1, const uint32_t* op2, const uint32_t* op3, mpfr_rnd_t rounding_mode, environment env);

int fnms(uint32_t* result, const uint32_t* op1, const uint32_t* op2, const uint32_t* op3, mpfr_rnd_t rounding_mode, environment env);

int sqrt(uint32_t* result, const uint32_t* op, mpfr_rnd_t rounding_mode, environment env);

int cmp_leq(uint32_t* result, const uint32_t* op1, const uint32_t* op2, environment env, bool print_details = false);

int cmp_lt(uint32_t* result, const uint32_t* op1, const uint32_t* op2, environment env, bool print_details = false);

int cmp_eq(uint32_t* result, const uint32_t* op1, const uint32_t* op2, environment env, bool print_details = false);

/// @brief 
/// @param result 
/// @param op1 
/// @param op2 
/// @param env 
int fmin(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env);

/// @brief 
/// @param result 
/// @param op1 
/// @param op2 
/// @param env 
int fmax(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env);

int fcvt_f2i32 (uint32_t* result, const uint32_t* op1, int is_signed, mpfr_rnd_t rounding_mode, environment env);
int fcvt_f2i64 (uint32_t* result, const uint32_t* op1, int is_signed, mpfr_rnd_t rounding_mode, environment env);
int fcvt_i2f(uint32_t* result, const uint32_t* op1, int is_signed, int int_format, mpfr_rnd_t rounding_mode, environment env);
int fcvt_f2f(uint32_t* result, const uint32_t* op1, mpfr_rnd_t rounding_mode, environment src_env, environment dst_env);

int fsgnj(uint32_t* result, const uint32_t* op1, const uint32_t* op2, mpfr_rnd_t rounding_mode, environment env);

int fmv_f2x(uint32_t* result, const uint32_t* op1, environment env, int nchunks);

int fclass(uint32_t* result, const uint32_t* input_IEEElike, environment env, bool print_details = false);

#endif // OPERATIONS_H_INCLUDED