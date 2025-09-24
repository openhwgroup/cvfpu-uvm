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
 *  Description   : Declare functions relatives to the representation of IEEE-754 floating point numbers
 *  History       :
 */

#ifndef MEMORY_H_INCLUDED
#define MEMORY_H_INCLUDED

#include <stdio.h>
#include <tgmath.h>
#include <stdarg.h>
#include <gmp.h>
#include <mpfr.h>
#include <cstdint>

//########## IEEE-LIKE SIZE ############################################################################################

#define IEEELIKE_INDEX_OF_LAST_DWORD(k) (ceil( (float) k/32 )-1) /**< index of last (32-bits) dword in IEEE-like array, regarding k, the scalar bit size */
#define IEEELIKE_INDEX_OF_LAST_QWORD(k) (ceil( (float) k/64 )-1) /**< index of last (64-bits) qword in IEEE-like array, regarding k, the scalar bit size */

/**
 * \brief   Compute the maximum exponent value, which is also the bias
 * \details Return 2^(w-1)-1, as define in IEEE 754\n
 *          Because w is up to 16 bits, uint16_t should be enough, but uint64_t is used here in case of higher w support in the future
 * \param   es   The bit size of the exponent field, one-based
 * \return  The maximum exponent value
 */
int64_t IEEElike_emax(uint8_t es);

/**
 * \brief   Compute the minimum exponent value
 * \details Return 1-emax, as define in IEEE 754\n
 *          Because w is up to 16 bits, uint16_t should be enough, but uint64_t is used here in case of higher w support in the future
 * \param   es   The bit size of the exponent field, one-based
 * \return  The minimum exponent value
 */
int64_t IEEElike_emin(uint8_t es);

/**
 * \brief   Compute the maximum value for the E field, (2^w)-1
 * \details It is the value of the E field for infinities and NaNs
 * \param   es   The bit size of the exponent field, one-based
 * \return  The maximum value for the E field
 */
uint64_t IEEElike_E_max(uint8_t es);

void IEEElike_set_exp_range(uint8_t es, uint16_t ms);

#define IEEELIKE_MAX_NUMBER_OF_CHARS_REQUIRED(ms) (26+64*(ms)) /**< when writing an IEEE-like into a char array following the notation "0b[hidden bit].[significand]p[exponent in decimal]", max number of chars is 1 (sign) + 4 (0b0. or 0b1.) + t (explicit significand) + 2 (exponent symbol + its sign) + ~18 (up to 58-bits signed exponent in decimal) + 1 (end of string) */

//########## FIELDS INDEXES ############################################################################################

#define IEEELIKE_T_LSB_INDEX                            (0)                         /**< overall index of the LSB of an IEEE-like's T field */
#define IEEELIKE_T_LSB_INDEX_AFTER_ZERO_PADDING(env)    (PADDING_SIZE(env))         /**< overall index of the LSB of an IEEE-like's T field, after the zero padding induced by bis%8!=0 */
#define PADDING_SIZE(env)                               (BYS(env.bis+1)*8-(env.bis+1))    /**< bit size of the zero padding induced by bis%8!=0 */
#define IEEELIKE_T_MSB_INDEX(ms)                        ((ms)-1)                    /**< overall index of the MSB of an IEEE-like's T field */
#define IEEELIKE_E_LSB_INDEX(ms)                        (ms)                        /**< overall index of the LSB of an IEEE-like's E field */
#define IEEELIKE_E_MSB_INDEX(ms,es)                     ((ms)+((es)+1)-1)               /**< overall index of the MSB of an IEEE-like's E field */
#define IEEELIKE_S_INDEX(ms,es)                         ((ms)+((es)+1))                /**< overall index of an IEEE-like's S field */

//########## IEEE-LIKE TYPE OF VALUE ###################################################################################

#define IEEELIKE_IS_NORMAL_NUMBER(E,E_max)          ((0 < (E)) && ((E) < (E_max)))      /**< identify if the IEEE-like represent a normal number */
#define IEEELIKE_IS_ZERO(E,T_is_null)               (((E)==0) && (T_is_null))           /**< identify if the IEEE-like represent zero */
#define IEEELIKE_IS_INF(E,E_max,T_is_null)          (((E)==(E_max)) && (T_is_null))     /**< identify if the IEEE-like represent infinity */
#define IEEELIKE_IS_NAN(E,E_max,T_is_null)          (((E)==(E_max)) && !(T_is_null))    /**< identify if the IEEE-like represent NaN */
#define IEEELIKE_IS_DENORMAL_NUMBER(E,T_is_null)    (((E)==0) && !(T_is_null))          /**< identify if the IEEE-like represent a denormal number */

//########## IEEE-LIKE MEMORY ENVIRONMENT ##############################################################################

/**
 * \brief Define a variable precision environment
 */
typedef struct
{
    //BYS is the BYte Size
    //k is the scalar bit size = BYS/8
    //w or ES is the exponent bit size
    //p or MS is the significand bit size -> t=p-1 explicit bits (hidden bit deduced from exponent), t+1 with sign bit

    uint16_t bis; /**< total BIt Size, one-based */
    uint8_t es; /**< Exponent Size, one-based */
} environment;

#define BIS(env)   ((env)+1)
#define ES(env)    ((env)+1)
#define BYS(bis)   (uint8_t)(ceil(((float)(bis))/8)) /**< compute BYte Size (zero-based) from BIt Size (one-based). If BIS is not a multiple of 8, zero padding */
#define K(bis)     ((BYS(bis))*8) /**< compute the aligned bit size (multiple of 8) (zero-based) from BYte Size (one-based) */
#define MS(env)    ((K(BIS(env.bis))) - ES(env.es) - 1) /**< compute Mantissa Size from environment (byte aligned) */
#define MBITS(env) (   BIS(env.bis)   - ES(env.es) - 1) /**< compute Mantissa Size from environment */

#define HALF_ENV_INITIALIZER { .bis = 16-1, .es = 5-1 } /**< Initialise an environment to the fields length of an IEEE 754 half : 16 bits, including the sign bit, 5 bits for the exponent and 10 explicit bits of significand */
#define FLOAT_ENV_INITIALIZER { .bis = 32-1, .es = 8-1 } /**< Initialise an environment to the fields length of an IEEE 754 float : 32 bits, including the sign bit, 8 bits for the exponent and 23 explicit bits of significand */
#define DOUBLE_ENV_INITIALIZER { .bis = 64-1, .es = 11-1 } /**< Initialise an environment to the fields length of an IEEE 754 double : 64 bits, including the sign bit, 11 bits for the exponent and 52 explicit bits of significand */

int get_flags(bool sNaN_inputs, bool qNaN_inputs);
int get_conv_flags();


//########## PRINTING #########################################################################################

/**
 * \brief   Print the sign, exponent and significand values of \e IEEElike
 * \details Access each field of the IEEE-like and display their values.\n
 *          The \e IEEElike array should have enough elements (regarding \e env)
 * \param   IEEElike    The IEEElike that will be printed
 * \param   env         The variable precision environment, defining the length of the fields
 */
void IEEElike_print_fields(const uint32_t* IEEElike, environment env);

/**
 * \brief   Print the value of \e IEEElike
 * \details If \e IEEElike is a normal or denormal number, the corresponding vp value is printed in binary (with the binary exponent in decimal) \n
 *          Else \e IEEElike store a special value (+/- 0, +/- Inf, qNaN or sNaN) which is printed \n
 *          The \e IEEElike array should have enough elements (regarding \e env)
 * \param   IEEElike    The IEEElike that will be printed
 * \param   env         The variable precision environment, defining the length of the fields
 */
void IEEElike_print_value(const uint32_t* IEEElike, environment env);

//########## READING FUNCTIONS #########################################################################################

/**
 * \brief   Return the E field of \e IEEElike
 * \details The \e IEEElike array should have enough elements (regarding \e w and \e t)
 * \param   IEEElike    The IEEE-like number on which we want to access the fields
 * \param   es           The bit size of the exponent field, one-based
 * \param   ms           The bit size of the trailing significand field (explicit significand bits), zero-based
 * \return  The value of the E field
 */
uint64_t IEEElike_get_E(const uint32_t* IEEElike, uint8_t es, uint16_t ms);

/**
 * \brief   Return the S field (sign bit) of \e IEEElike
 * \details The \e IEEElike array should have enough elements (regarding \e w and \e t)
 * \param   IEEElike    The IEEE-like number on which we want to access the fields
 * \param   es           The bit size of the exponent field, one-based
 * \param   ms           The bit size of the trailing significand field (explicit significand bits), zero-based
 * \return  1 if \e IEEElike is negative, else 0
 */
bool IEEElike_get_S(const uint32_t* IEEElike, uint8_t es, uint16_t ms);

/**
 * \brief   Return true if the T field of \e IEEElike is null (only zeros)
 * \details The \e IEEElike array should have enough elements (regarding \e t)
 * \param   IEEElike    The IEEE-like number on which we want to access the fields
 * \param   env         The variable precision environment, defining the length of the fields
 * \return  1 if the T field of \e IEEElike only contains 0s, else 0
 */
bool IEEElike_T_is_null(const uint32_t* IEEElike, environment env);

bool IEEElike_is_sNaN (const uint32_t* IEEElike, environment env);
bool IEEElike_is_qNaN (const uint32_t* IEEElike, environment env);
bool IEEElike_is_Inf (const uint32_t* IEEElike, environment env);
bool IEEElike_is_Zero (const uint32_t* IEEElike, environment env);


//########## WRITING ##################################################################################################

/**
 * \brief   Set the value of the IEEE-like operand \e op to zero
 * \param   op          The IEEE-like operand
 * \param   es           The exponent bit size, one-based
 * \param   ms           The explicit significand bit size, zero-based
 * \param   sign_bit    If 1, the value will be set to -0, else +0
 */
void IEEElike_set_to_0(uint32_t* op, uint8_t es, uint16_t ms, bool sign_bit);

/**
 * \brief   Set the value of the IEEE-like operand \e op to Inf
 * \param   op          The IEEE-like operand
 * \param   es           The exponent bit size, one-based
 * \param   ms           The explicit significand bit size, zero-based
 * \param   sign_bit    If 1, the value will be set to -Inf, else +Inf
 */
void IEEElike_set_to_Inf(uint32_t* op, uint8_t es, uint16_t ms, bool sign_bit);

/**
 * \brief   Set the value of the IEEE-like operand \e op to quiet NaN
 * \param   op  The IEEE-like operand
 * \param   es   The exponent bit size, one-based
 * \param   ms   The explicit significand bit size, zero-based
 */
void IEEElike_set_to_qNaN(uint32_t* op, uint8_t es, uint16_t ms);

/**
 * \brief   Set the value of the IEEE-like operand \e op to signaling NaN
 * \param   op  The IEEE-like operand
 * \param   es   The exponent bit size, one-based
 * \param   ms   The explicit significand bit size, zero-based
 */
void IEEElike_set_to_sNaN(uint32_t* op, uint8_t es, uint16_t ms);

/**
 * \brief   Check if \e exponent can be stored in a IEEE-like. If not, manage over/underflow.
 * \details If \e exponent is too large regarding \e IEEElike_get_emax, overflows towards +/- Inf and returns false \n
 *          Else if \e exponent is too small regarding \e IEEElike_get_emin, underflows towards +/- 0 and returns false \n
 *          Else \e exponent biased fits in the E field of a IEEE-like, returns true \n
 *          The sign bit should be set externally
 * \param   output          The output IEEE-like
 * \param   exponent        The exponent value to try to store in the IEEE-like
 * \param   ms               The bit size of the T field (number of explicit bits), zero-based
 * \param   es               The bit size of the E field, one-based
 * \param   print_details   If true, debugging informations will be printed
 * \return  True if \e exponent can fit, else false
 */
bool IEEElike_exponent_fits(uint32_t* output, mpfr_t input_mpfr, int64_t exponent, environment env, mpfr_rnd_t rounding_mode, bool print_details = false);
void mpfr2IEEElike_subnormal(uint32_t* output_IEEElike, mpfr_t input_mpfr, environment env, mpfr_rnd_t rounding_mode, bool print_details = false);

//########## CONVERSION TO CHAR ARRAY ##################################################################################

/**
 * \brief   Write the significand value and the exponent value into a char array
 * \details Enough memory should be allocated for \e output_str before
 * \param   output_str              Output variable. Where to write the significand and the exponent as char array
 * \param   input_IEEElike          Pointer to the IEEE-like (array of uint32_t) where the significand will be read
 * \param   significand_start_index The IEEE-like bit index at which the copy will start (different from the MSB in case of denormal number)
 * \param   exponent                The exponent value
 * \param   padding_size            The bit size of the zero-padding
 * \param   print_details           If true, debugging informations will be printed.
 * \return  Number of chars written in \e output_str, including NULL char
 */
uint16_t IEEElike_write_significand_and_exponent(char* output_str, const uint32_t* input_IEEElike, uint16_t significand_start_index, int64_t exponent, uint8_t padding_size = 0, bool print_details = false);

/**
 * \brief   Write an IEEE-like value (normal or denormal number only) into a char array
 * \details Enough memory should be allocated for \e output_str before, see IEEELIKE_MAX_NUMBER_OF_CHARS_REQUIRED
 *          If \e input_IEEElike is neither a normal nor a denormal number, the function will not write anything
 * \param   output_str          Output variable. Where to write \e input_IEEElike as char array
 * \param   input_IEEElike      Input variable. Pointer to an IEEE-like (array of uint32_t).
 * \param   es                   The exponent bit size, one-based
 * \param   ms                   The explicit significand bit size, zero-based
 * \param   is_normal_number    True if \e input_IEEElike is a normal number, false if it is a denormal one
 * \param   padding_size        Bit size of the zero-padding induced by bis%8!=0
 * \param   print_details       If true, debugging informations will be printed.
 * \return  Number of chars written in \e output_str
 */
uint16_t IEEElike2str(char* output_str, const uint32_t* input_IEEElike, uint8_t es, uint16_t ms, bool is_normal_number = true, uint8_t padding_size = 0, bool print_details = false);

//########## CONVERSIONS FROM AND TO MPFR VARIABLES ####################################################################

/**
 * \brief   Convert an IEEE-like to a mpfr_t
 * \details \e output_mpfr should not be initialised (mpfr_init()), it will be done inside the function with the right precision.
 * \param   output_mpfr         Output variable. Where to write \e input_IEEElike converted to a mpfr_t. Should be declared but not initialised.
 * \param   input_IEEElike      Input variable. Pointer to an IEEE-like (array of uint32_t).
 * \param   env                 The variable precision environment, defining the fields length of \e input_IEEElike
 * \param   rounding_mode       The rounding mode to be used. See MPFR documentation.
 * \param   precision           If 0, the same precision as the input IEEE-like will be used. Else the value of \e precision.
 * \param   print_details       If true, debugging informations will be printed.
 */
void IEEElike2mpfr(mpfr_t output_mpfr, const uint32_t* input_IEEElike, environment env, mpfr_rnd_t rounding_mode, uint16_t precision = 0, bool print_details = false);

/**
 * \brief   Convert a mpfr_t to an IEEE-like
 * \details 
 * \param   output_IEEElike     Output variable. Where to write \e input_mpfr converted to an IEEE-like.
 * \param   input_mpfr          Input variable. mpfr_t number.
 * \param   env                 The variable precision environment, defining the fields length of \e output_IEEElike
 * \param   rounding_mode       The rounding mode to be used. See MPFR documentation.
 * \param   print_details       If true, debugging informations will be printed.
 */
void mpfr2IEEElike(uint32_t* output_IEEElike, mpfr_t input_mpfr, environment env, mpfr_rnd_t rounding_mode, bool print_details = false);

//########## COMPARISON ################################################################################################

/**
 * \brief   Test if the significand of 2 IEEE-like are equal
 * \param   op1             First operand of the comparison.
 * \param   ms1              Number of explicit bits for the significand of \e op1, zero-based
 * \param   op2             Second operand of the comparison.
 * \param   ms2              Number of explicit bits for the significand of \e op1, zero-based
 * \param   print_details   If true, debugging informations will be printed.
 * \return  true if significands are equal, else false
 */
bool IEEElike_same_significand(const uint32_t* op1, uint8_t ms1,const uint32_t* op2, uint8_t ms2, bool print_details = false);

#endif //MEMORY_H_INCLUDED
