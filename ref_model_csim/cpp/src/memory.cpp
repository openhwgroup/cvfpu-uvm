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
 *  Description   : Contains functions that handle IEEE-754 2008 representation to/from MPFR
 *  History       :
 */

#include <stdio.h>
#include <stdarg.h>
#include <tgmath.h>//for pow()
#include <gmp.h>
#include <mpfr.h>
#include <cstdint>
#include "bitwise.h"
#include "memory.h"


int get_flags(bool sNaN_inputs, bool qNaN_inputs)
{
    int exc_flags = 0;
    
	if (mpfr_inexflag_p())
	{
        SET_BIT_TO_1__DWORD(exc_flags, 0);
	}
	// In IEEE-745 the underflow flag is set only when the result
	// is inexaxt. In MPFR, the underflow flag is raised even when
	// the result is exact
    if (mpfr_underflow_p() && mpfr_inexflag_p())
        SET_BIT_TO_1__DWORD(exc_flags, 1);
    if (mpfr_overflow_p())
        SET_BIT_TO_1__DWORD(exc_flags, 2);
    if (mpfr_divby0_p())
		SET_BIT_TO_1__DWORD(exc_flags, 3);
    if (mpfr_nanflag_p())
	{
		if (sNaN_inputs)
			SET_BIT_TO_1__DWORD(exc_flags, 4);
		else if (!qNaN_inputs)
			SET_BIT_TO_1__DWORD(exc_flags, 4);
	}
	if (mpfr_erangeflag_p()) 
	{
		SET_BIT_TO_1__DWORD(exc_flags, 4);
		
	}
    return exc_flags;
}


int get_conv_flags()
{
    int exc_flags = 0;
    
	if (mpfr_erangeflag_p()) 
	{
		SET_BIT_TO_1__DWORD(exc_flags, 4);
	}
	if (mpfr_inexflag_p())
	{
        SET_BIT_TO_1__DWORD(exc_flags, 0);
	}

    return exc_flags;
}


int64_t IEEElike_emax(uint8_t es)
{
    int64_t emax = 0x0000000000000000;
    for(uint8_t index = 0; index <= (es+1)-2; index++)
    {
        SET_BIT_TO_1__QWORD(emax,index);
    }
    return emax;
}

int64_t IEEElike_emin(uint8_t es)
{
    return 1-IEEElike_emax(es);
}

uint64_t IEEElike_E_max(uint8_t es)
{
    uint64_t E_max = 0x0000000000000000;
    for(uint8_t index = 0; index <= (es+1)-1; index++)
    {
        SET_BIT_TO_1__QWORD(E_max,index);
    }
    return E_max;
}

void IEEElike_set_exp_range(uint8_t es, uint16_t ms)
{
    uint64_t emax, emin;
    emax = IEEElike_emax(es) + 1;
    emin = IEEElike_emin(es) - ms + 1;
	
    mpfr_set_emin(emin);
    mpfr_set_emax(emax);
}

void IEEElike_print_fields(const uint32_t* IEEElike, environment env)
{
    // uint16_t k = K(env.bis);//scalar bit size
    uint16_t ms = MS(env);//number of explicit bits for the significand

    printf("S = %u\n",IEEElike_get_S(IEEElike,env.es,ms));

    uint64_t E = IEEElike_get_E(IEEElike,env.es,ms);
    printf("E = "); print_in_binary<uint64_t>(E,env.es+1); printf(" = %lu\n",E);

    if(IEEELIKE_IS_NORMAL_NUMBER(E,env.es))
    {
        printf("-> exponent = %ld\n",E-IEEElike_emax(env.es));
    }

    printf("T = ");
    for(int32_t index_in_array = IEEELIKE_T_MSB_INDEX(ms); index_in_array >= IEEELIKE_T_LSB_INDEX_AFTER_ZERO_PADDING(env); index_in_array--)//for each bit of T
    {
        printf("%u",(bool) GET_BIT__DWORD_ARRAY(IEEElike,index_in_array));
    }
    putchar('\n');
}

void IEEElike_print_value(const uint32_t* IEEElike, environment env)
{
    // uint16_t k = K(env.bis);//scalar bit size
    uint16_t ms = MS(env);//number of explicit bits for the significand

    //check if T is 0
    bool T_is_null = IEEElike_T_is_null(IEEElike,env);
    
    //get E value
    uint64_t E = IEEElike_get_E(IEEElike,env.es,ms);

    //compute E_max
    uint64_t E_max = IEEElike_E_max(env.es);

    //get sign
    bool sign_bit = IEEElike_get_S(IEEElike,env.es,ms);
    
    if(IEEELIKE_IS_ZERO(E,T_is_null))//case +/- 0
    {
        if(sign_bit) { putchar('-'); }//if sign bit == 1
        printf("0");
    }
    else if(IEEELIKE_IS_INF(E,E_max,T_is_null))//case +/- inf
    {
        if(sign_bit) { putchar('-'); } else { putchar('+'); }
        printf("Inf");
    }
    else if(IEEELIKE_IS_NAN(E,E_max,T_is_null))//case NaN
    {
        //MSB of T determines if it is a quiet NaN of a signaling one
        if(GET_BIT__DWORD_ARRAY(IEEElike,IEEELIKE_T_MSB_INDEX(ms))) { printf("quiet NaN"); } //MSB of T is 1 -> quiet NaN
        else { printf("signaling NaN"); } //MSB of T is 0 -> signaling NaN
    }
    else if(IEEELIKE_IS_DENORMAL_NUMBER(E,T_is_null))//case denormal number
    {
        if(sign_bit) { putchar('-'); }//if sign bit == 1
        printf("0.");
        for(int32_t index_in_array = IEEELIKE_T_MSB_INDEX(ms); index_in_array >= IEEELIKE_T_LSB_INDEX; index_in_array--)//for each bit of T
        {
            printf("%u",(bool) GET_BIT__DWORD_ARRAY(IEEElike,index_in_array));
        }
        printf("e%ld",IEEElike_emin(env.es));
    }
    else//case normal number
    {
        if(sign_bit) { putchar('-'); }//if sign bit == 1
        printf("1.");
        for(int32_t index_in_array = IEEELIKE_T_MSB_INDEX(ms); index_in_array >= IEEELIKE_T_LSB_INDEX; index_in_array--)//for each bit of T
        {
            printf("%u",(bool) GET_BIT__DWORD_ARRAY(IEEElike,index_in_array));
        }
        printf("e%ld",E-IEEElike_emax(env.es));
    }
}

uint64_t IEEElike_get_E(const uint32_t* IEEElike, uint8_t es, uint16_t ms)
{
    uint64_t E = 0;
    for(uint16_t index_in_array = IEEELIKE_E_LSB_INDEX(ms); index_in_array <= IEEELIKE_E_MSB_INDEX(ms,es); index_in_array++)
    {
        if(GET_BIT__DWORD_ARRAY(IEEElike,index_in_array))
        {
            SET_BIT_TO_1__QWORD(E,index_in_array-ms);//index in E field = index in array - ms
        }
        //else : already 0
    }
    return E;
}

bool IEEElike_get_S(const uint32_t* IEEElike, uint8_t es, uint16_t ms)
{
    return GET_BIT__DWORD_ARRAY(IEEElike,IEEELIKE_S_INDEX(ms,es));
}

bool IEEElike_T_is_null(const uint32_t* IEEElike, environment env)
{
    bool T_is_null = true;
    for(uint16_t index_in_array = IEEELIKE_T_LSB_INDEX_AFTER_ZERO_PADDING(env); index_in_array <= IEEELIKE_T_MSB_INDEX(MS(env)); index_in_array++)
    {
        if(GET_BIT__DWORD_ARRAY(IEEElike,index_in_array) != 0)
        {
            T_is_null = false;//at least one bit of T is 1
            break;
        }
    }
    return T_is_null;
}

bool IEEElike_is_sNaN (const uint32_t* IEEElike, environment env)
{
	//check if T is 0
    bool T_is_null = IEEElike_T_is_null(IEEElike,env);
    
    //get E value
    uint64_t E = IEEElike_get_E(IEEElike, env.es, MBITS(env));

    //compute E_max
    uint64_t E_max = IEEElike_E_max(env.es);

	bool is_signaling = !GET_BIT__DWORD_ARRAY(IEEElike,MBITS(env)-1);
	bool is_nan = IEEELIKE_IS_NAN(E,E_max,T_is_null);
	
	/*
	if (is_signaling & is_nan)
		printf("operand is sNaN\n");
	*/
	return (is_signaling & is_nan);
}   

bool IEEElike_is_qNaN (const uint32_t* IEEElike, environment env)
{
	//check if T is 0
    bool T_is_null = IEEElike_T_is_null(IEEElike,env);
    
    //get E value
    uint64_t E = IEEElike_get_E(IEEElike, env.es, MBITS(env));

    //compute E_max
    uint64_t E_max = IEEElike_E_max(env.es);

	bool is_signaling = !GET_BIT__DWORD_ARRAY(IEEElike,MBITS(env)-1);
	bool is_nan = IEEELIKE_IS_NAN(E,E_max,T_is_null);
	
	return (!is_signaling & is_nan);
} 

bool IEEElike_is_Inf (const uint32_t* IEEElike, environment env)
{
	//check if T is 0
    bool T_is_null = IEEElike_T_is_null(IEEElike,env);
    
    //get E value
    uint64_t E = IEEElike_get_E(IEEElike, env.es, MBITS(env));

    //compute E_max
    uint64_t E_max = IEEElike_E_max(env.es);
	
	return IEEELIKE_IS_INF(E,E_max,T_is_null);

}

bool IEEElike_is_Zero (const uint32_t* IEEElike, environment env)
{
	//check if T is 0
    bool T_is_null = IEEElike_T_is_null(IEEElike,env);
    
    //get E value
    uint64_t E = IEEElike_get_E(IEEElike, env.es, MBITS(env));
	
	return IEEELIKE_IS_ZERO(E,T_is_null);

}

void IEEElike_set_to_0(uint32_t* op, uint8_t es, uint16_t ms, bool sign_bit)
{
    //set S field value
    if(sign_bit)//if sign bit == 1
    {
        SET_BIT_TO_1__DWORD_ARRAY(op,IEEELIKE_S_INDEX(ms,es));//S set to 1
    }
    else
    {
        SET_BIT_TO_0__DWORD_ARRAY(op,IEEELIKE_S_INDEX(ms,es));//S set to 0
    }

    //set E field value and T field value to 0s
    for(int16_t index_in_IEEElike = IEEELIKE_E_MSB_INDEX(ms,es); index_in_IEEElike >= IEEELIKE_T_LSB_INDEX; index_in_IEEElike--)//from MSB of E to LSB of T
    {
        SET_BIT_TO_0__DWORD_ARRAY(op,index_in_IEEElike);
    }
}

void IEEElike_set_to_Inf(uint32_t* op, uint8_t es, uint16_t ms, bool sign_bit)
{
    //set S field value
    if(sign_bit)//if sign bit == 1
    {
        SET_BIT_TO_1__DWORD_ARRAY(op,IEEELIKE_S_INDEX(ms,es));//S set to 1
    }
    else
    {
        SET_BIT_TO_0__DWORD_ARRAY(op,IEEELIKE_S_INDEX(ms,es));//S set to 0
    }

    //set E field value to 1s
    for(int16_t index_in_IEEElike = IEEELIKE_E_MSB_INDEX(ms,es); index_in_IEEElike >= IEEELIKE_E_LSB_INDEX(ms); index_in_IEEElike--)//from MSB to LSB of E
    {
        SET_BIT_TO_1__DWORD_ARRAY(op,index_in_IEEElike);
    }

    //set T field value to 0s
    for(int16_t index_in_IEEElike = IEEELIKE_T_MSB_INDEX(ms); index_in_IEEElike >= IEEELIKE_T_LSB_INDEX; index_in_IEEElike--)//from MSB to LSB of T
    {
        SET_BIT_TO_0__DWORD_ARRAY(op,index_in_IEEElike);
    }
}

void IEEElike_set_to_qNaN(uint32_t* op, uint8_t es, uint16_t ms)
{
    //set S field value
    SET_BIT_TO_0__DWORD_ARRAY(op,IEEELIKE_S_INDEX(ms,es));//sign bit to 0

    //set E field value to 1s
    for(int16_t index_in_IEEElike = IEEELIKE_E_MSB_INDEX(ms,es); index_in_IEEElike >= IEEELIKE_E_LSB_INDEX(ms); index_in_IEEElike--)//from MSB to LSB of E
    {
        SET_BIT_TO_1__DWORD_ARRAY(op,index_in_IEEElike);
    }

    //set T field value to to 100...0
    SET_BIT_TO_1__DWORD_ARRAY(op,IEEELIKE_T_MSB_INDEX(ms));//quiet NaN -> MSB of T set to 1
    for(int16_t index_in_IEEElike = IEEELIKE_T_MSB_INDEX(ms)-1; index_in_IEEElike >= IEEELIKE_T_LSB_INDEX; index_in_IEEElike--)//from MSB-1 to LSB+1
    {
        SET_BIT_TO_0__DWORD_ARRAY(op,index_in_IEEElike);
    }
}

void IEEElike_set_to_sNaN(uint32_t* op, uint8_t es, uint16_t ms)
{
    //set S field value
    SET_BIT_TO_0__DWORD_ARRAY(op,IEEELIKE_S_INDEX(ms,es));//sign bit to 0

    //set E field value to 1s
    for(int16_t index_in_IEEElike = IEEELIKE_E_MSB_INDEX(ms,es); index_in_IEEElike >= IEEELIKE_E_LSB_INDEX(ms); index_in_IEEElike--)//from MSB to LSB
    {
        SET_BIT_TO_1__DWORD_ARRAY(op,index_in_IEEElike);
    }

    //set T field value to 010...0
    SET_BIT_TO_0__DWORD_ARRAY(op,IEEELIKE_T_MSB_INDEX(ms));//signaling NaN -> MSB of T set to 0
    SET_BIT_TO_1__DWORD_ARRAY(op,IEEELIKE_T_MSB_INDEX(ms)-1);
    for(int16_t index_in_IEEElike = IEEELIKE_T_MSB_INDEX(ms)-2; index_in_IEEElike >= IEEELIKE_T_LSB_INDEX; index_in_IEEElike--)//from MSB-2 to LSB
    {
        SET_BIT_TO_0__DWORD_ARRAY(op,index_in_IEEElike);
    }
}

void mpfr2IEEElike_subnormal(uint32_t* output_IEEElike, mpfr_t input_mpfr, environment env, mpfr_rnd_t rounding_mode, bool print_details)
{   
    uint16_t ms = MS(env);//number of explicit bits for the significand
    mpfr_exp_t exponent = 0;
    char* result_str = mpfr_get_str(NULL,&exponent,2,0,input_mpfr,MPFR_RNDN);//get significand in binary as char array, and exponent

    if(print_details)
    {
        printf("subnormal string : %s\n",result_str);
        printf("subnormal exponent : %ld\n",exponent);
    }

    uint16_t index_in_trailing_bits = 0;
    uint8_t offset_for_str = 1;//start at the 2nd bit (index 1), hide the leading 1 bit

    //set S field
    if(result_str[0] == '-')//in case of negative number
    {
        SET_BIT_TO_1__DWORD_ARRAY(output_IEEElike,IEEELIKE_S_INDEX(ms,env.es));
        offset_for_str++;
    }
    else
    {
        SET_BIT_TO_0__DWORD_ARRAY(output_IEEElike,IEEELIKE_S_INDEX(ms,env.es));
    }
    // Set E field
    if ( (exponent == IEEElike_emin(env.es) +1)) // The output is a normal number after normalisation, set E field to 1
    {
        for(int32_t index_in_IEEElike = IEEELIKE_E_MSB_INDEX(ms,env.es); index_in_IEEElike >= IEEELIKE_E_LSB_INDEX(ms) +1; index_in_IEEElike--)//from MSB to LSB+1
        {
            SET_BIT_TO_0__DWORD_ARRAY(output_IEEElike,index_in_IEEElike);
        }
        SET_BIT_TO_1__DWORD_ARRAY(output_IEEElike,IEEELIKE_E_LSB_INDEX(ms));
    }
    else { //set E field to 00...0
        for(int32_t index_in_IEEElike = IEEELIKE_E_MSB_INDEX(ms,env.es); index_in_IEEElike >= IEEELIKE_E_LSB_INDEX(ms); index_in_IEEElike--)//from MSB to LSB
        {
            SET_BIT_TO_0__DWORD_ARRAY(output_IEEElike,index_in_IEEElike);
        }
    }

    //set T field
    for(int32_t index_in_IEEElike = IEEELIKE_T_MSB_INDEX(ms); index_in_IEEElike >= IEEELIKE_T_LSB_INDEX; index_in_IEEElike--)//from MSB to LSB
    {
        if (index_in_IEEElike >= ms - (IEEElike_emin(env.es) - exponent) )
        {
            SET_BIT_TO_0__DWORD_ARRAY(output_IEEElike,index_in_IEEElike);
            // printf("i_zeros= %d, ", index_in_IEEElike);

        }
        else if (index_in_IEEElike == ms - (IEEElike_emin(env.es) - exponent) -1)
        {
            SET_BIT_TO_1__DWORD_ARRAY(output_IEEElike, index_in_IEEElike);
        }
        else if (index_in_IEEElike >=  IEEELIKE_T_MSB_INDEX(ms) - MBITS(env) +1)
        {   
            if(result_str[index_in_trailing_bits+offset_for_str] == '1')
            {
                SET_BIT_TO_1__DWORD_ARRAY(output_IEEElike, index_in_IEEElike);
            }
            else// if(result_str[index_in_trailing_bits+offset_for_str] == '0') //assume there are ony '1's and '0's
            {
                SET_BIT_TO_0__DWORD_ARRAY(output_IEEElike, index_in_IEEElike);
            }
            index_in_trailing_bits++;//read next char in next loop
        } else
        {
            SET_BIT_TO_0__DWORD_ARRAY(output_IEEElike,index_in_IEEElike);
        }
    }   
    mpfr_free_str(result_str);
    
    if(print_details) { printf("IEEE-like output = \n"); IEEElike_print_fields(output_IEEElike,env); putchar('\n'); }
}

bool IEEElike_exponent_fits(uint32_t* output, mpfr_t input_mpfr, int64_t exponent, environment env, mpfr_rnd_t rounding_mode, bool print_details)
{
    mpfr_t mpfr_rounded;
    uint16_t ms = MS(env);
    uint16_t ms_bits = MBITS(env);
    
    if(exponent > IEEElike_emax(env.es))
    {
        //overflow towards +/- Inf
        //set E field to 11...1
        for(int32_t index_in_IEEElike = IEEELIKE_E_MSB_INDEX(ms,env.es); index_in_IEEElike >= IEEELIKE_E_LSB_INDEX(ms); index_in_IEEElike--)//from MSB to LSB
        {
            SET_BIT_TO_1__DWORD_ARRAY(output,index_in_IEEElike);
        }
        //set T field to 00...0
        for(int32_t index_in_IEEElike = IEEELIKE_T_MSB_INDEX(ms); index_in_IEEElike >= IEEELIKE_T_LSB_INDEX; index_in_IEEElike--)//from MSB to LSB
        {
            SET_BIT_TO_0__DWORD_ARRAY(output,index_in_IEEElike);
        }
        if(print_details) { printf("Exponent value too large for an IEEE-like -> overflow towards +/- Inf\n"); }
        return false;//no, does not fit
    }
    else if(exponent < IEEElike_emin(env.es))
    {   
        if ( exponent >= IEEElike_emin(env.es) - (ms_bits) )
        {   
            if(print_details) { printf("subnormal case\n"); }
            mpfr_prec_t prec_sub = ms_bits - (IEEElike_emin(env.es) - exponent) + 1;
            mpfr_init2(mpfr_rounded, prec_sub);

            mpfr_set(mpfr_rounded, input_mpfr, rounding_mode);
        
            if(print_details) { printf("mpfr rounded = "); mpfr_dump(mpfr_rounded); putchar('\n'); }
            mpfr2IEEElike_subnormal(output, mpfr_rounded, env, rounding_mode);
            return false;//no, does not fit
        }
        else {
            //underflow towards +/- 0
            //set E field to 00...0
            for(int32_t index_in_IEEElike = IEEELIKE_E_MSB_INDEX(ms,env.es); index_in_IEEElike >= IEEELIKE_E_LSB_INDEX(ms); index_in_IEEElike--)//from MSB to LSB
            {
                SET_BIT_TO_0__DWORD_ARRAY(output,index_in_IEEElike);
            }
            //set T field to 00...0
            for(int32_t index_in_IEEElike = IEEELIKE_T_MSB_INDEX(ms); index_in_IEEElike >= IEEELIKE_T_LSB_INDEX; index_in_IEEElike--)//from MSB to LSB
            {
                SET_BIT_TO_0__DWORD_ARRAY(output,index_in_IEEElike);
            }
            if(print_details) { printf("Exponent value too small for an IEEE-like -> underflow towards +/- 0\n"); }

            return false;//no, does not fit
        }
    }
    else//exponent biased fits in E field of IEEE-like
    {
        return true;//yes, fits
    }
}

bool IEEElike_same_significand(const uint32_t* op1, uint16_t ms1,const uint32_t* op2, uint16_t ms2, bool print_details)
{
    uint16_t smallest_ms = std::min(ms1,ms2);
    uint16_t ms_diff = std::abs(ms1-ms2);
    const uint32_t *IEEElike_of_longest_T = (ms1 >= ms2) ? op1 : op2, *IEEElike_of_shortest_T = (ms1 >= ms2) ? op2 : op1;
    //for each bit of the common length
    for(int16_t index_in_IEEElike_of_shortest_T = IEEELIKE_T_MSB_INDEX(smallest_ms); index_in_IEEElike_of_shortest_T >= 0; index_in_IEEElike_of_shortest_T--)//for each bit of the smallest T
    {
        if( GET_BIT__DWORD_ARRAY(IEEElike_of_shortest_T,index_in_IEEElike_of_shortest_T) != GET_BIT__DWORD_ARRAY(IEEElike_of_longest_T,index_in_IEEElike_of_shortest_T+ms_diff) )
        {
            if(print_details) { printf("the significand are differents on the common length\n"); }
            return false;
        }
    }
    if (ms_diff) {
        for(int16_t index_in_IEEElike_of_longest_T = ms_diff; index_in_IEEElike_of_longest_T >= 0; index_in_IEEElike_of_longest_T--)//for each remaining bits of the longest T
        {
            if( GET_BIT__DWORD_ARRAY(IEEElike_of_longest_T,index_in_IEEElike_of_longest_T) != 0)
            {
                if(print_details) { printf("the least significant bits of the one with the longest T are not all 0s\n"); }
                return false;
            }
        }
    }
    if(print_details) { printf("same significand\n"); }
    return true;
}

uint16_t IEEElike_write_significand_and_exponent(char* output_str, const uint32_t* input_IEEElike, uint16_t significand_start_index, int64_t exponent, uint8_t padding_size, bool print_details)
{
    uint16_t index_in_str = 0;//store the current index in the char array output_str
    // for(int16_t index_in_input_IEEElike = significand_start_index; index_in_input_IEEElike >= IEEELIKE_T_LSB_INDEX; index_in_input_IEEElike--)//for each bit of significand, from significand_start_index to LSB
    for(int16_t index_in_input_IEEElike = significand_start_index; index_in_input_IEEElike >= padding_size; index_in_input_IEEElike--)
    {
        if(GET_BIT__DWORD_ARRAY(input_IEEElike,index_in_input_IEEElike))
        {
            output_str[index_in_str] = '1'; index_in_str++;
        }
        else
        {
            output_str[index_in_str] = '0'; index_in_str++;
        }
    }
    output_str[index_in_str] = 'p'; index_in_str++;//p -> binary exponent (always base 2)
    index_in_str += sprintf(output_str+index_in_str,"%ld",exponent);//write exponent at current index and get the number of char written
    //NULL char already written by sprintf
    return index_in_str+1;//length including NULL char
}

uint16_t IEEElike2str(char* output_str, const uint32_t* input_IEEElike, uint8_t es, uint16_t ms, bool is_normal_number, uint8_t padding_size, bool print_details)
{
    char hidden_bit = 0;
    int64_t exponent = 0;

    if(is_normal_number)
    {
        hidden_bit = '1';
        exponent = IEEElike_get_E(input_IEEElike,es,ms)-IEEElike_emax(es);
        if(print_details) { printf("IEEE-like input is a normal number -> hidden bit is 1 and exponent is E-emax\n"); }
    }
    else//then it should be a denormal number
    {
        hidden_bit = '0';
        exponent = IEEElike_emin(es);
        if(print_details) { printf("IEEE-like input is a denormal number -> hidden bit is 0 and exponent is emin\n"); }
    }

    uint16_t index_in_str = 0;//store the current index in the char array output_str
    if(IEEElike_get_S(input_IEEElike,es,ms))//if negatif number
    {
        output_str[index_in_str] = '-'; index_in_str++;
    }
    output_str[index_in_str] = '0'; index_in_str++;
    output_str[index_in_str] = 'b'; index_in_str++;
    output_str[index_in_str] = hidden_bit; index_in_str++;
    output_str[index_in_str] = '.'; index_in_str++;
    index_in_str += IEEElike_write_significand_and_exponent(output_str+index_in_str,input_IEEElike,IEEELIKE_T_MSB_INDEX(ms),exponent,padding_size,print_details);//write significand and exponent at current index and get the number of char written
    if(print_details) { printf("output string = %s (length without \\0 = %u)\n",output_str,index_in_str-1); }
    return index_in_str+1;//length including NULL char
}

void IEEElike2mpfr(mpfr_t output_mpfr, const uint32_t* input_IEEElike, environment env, mpfr_rnd_t rounding_mode, uint16_t precision, bool print_details)
{
    if(print_details) { printf("IEEE-like input = "); IEEElike_print_value(input_IEEElike,env); putchar('\n'); }

    // uint16_t k = K(env.bis);//scalar bit size
    uint16_t ms = MS(env);//number of explicit bits for the significand

    //check if T is 0
    bool T_is_null = IEEElike_T_is_null(input_IEEElike,env);
    
    //get E value
    uint64_t E = IEEElike_get_E(input_IEEElike,env.es,ms);

    //compute E_max
    uint64_t E_max = IEEElike_E_max(env.es);

    //get sign
    bool sign_bit = IEEElike_get_S(input_IEEElike,env.es,ms);
    
    int mpfr_sign = sign_bit ? -1 : 1;

    //set precision
    if(precision==0)
    {
        mpfr_init2(output_mpfr,ms+1);//MPFR includes the hidden bit, so ms+1
        //TODO check if ms-1 is not too big (MPFR_PREC_MAX)
    }
    else
    {
        mpfr_init2(output_mpfr,precision);//use the value given as parameter for the precision
        //TODO check if precision is not too big (MPFR_PREC_MAX)
    }
    
    if(IEEELIKE_IS_ZERO(E,T_is_null))//case +/- 0
    {
        mpfr_set_zero(output_mpfr,mpfr_sign);
        if(print_details) { printf("IEEE-like input is zero -> MPFR output set to zero with same sign\n"); }
    }
    else if(IEEELIKE_IS_INF(E,E_max,T_is_null))//case +/- inf
    {
        mpfr_set_inf(output_mpfr,mpfr_sign);
        if(print_details) { printf("IEEE-like input is infinity -> MPFR output set to Inf with same sign\n"); }
    }
    else if(IEEELIKE_IS_NAN(E,E_max,T_is_null))//case NaN
    {
        //MPFR does not distinguish qNaN and sNaN
        mpfr_set_nan(output_mpfr);
        if(print_details) { printf("IEEE-like input is quiet NaN or signaling NaN -> MPFR output set to NaN\n"); }
    }
    else//case normal or denormal number
    {
        const uint16_t max_number_of_chars_required = IEEELIKE_MAX_NUMBER_OF_CHARS_REQUIRED(ms);
        char input_as_str[max_number_of_chars_required];
        uint16_t length = IEEElike2str(input_as_str,input_IEEElike,env.es,ms,!IEEELIKE_IS_DENORMAL_NUMBER(E,T_is_null),PADDING_SIZE(env), false);
        if(print_details) { printf("string used to set mpfr value : %s (length without \\0 = %u)\n",input_as_str,length); }
        mpfr_set_str(output_mpfr,input_as_str,0,rounding_mode);
    }
    if(print_details) { printf("mpfr output = "); mpfr_dump(output_mpfr); putchar('\n'); }
}

void mpfr2IEEElike(uint32_t* output_IEEElike, mpfr_t input_mpfr, environment env, mpfr_rnd_t rounding_mode, bool print_details)
{
    if(print_details) { printf("mpfr input = "); mpfr_dump(input_mpfr); putchar('\n'); }

    // uint16_t k = K(env.bis);//scalar bit size
    uint16_t ms = MS(env);//number of explicit bits for the significand

    mpfr_exp_t exponent = 0;
    char* result_str = mpfr_get_str(NULL,&exponent,2,0,input_mpfr,MPFR_RNDN);//get significand in binary as char array, and exponent

    //manage special values
    if(mpfr_nan_p(input_mpfr))
    {
        IEEElike_set_to_qNaN(output_IEEElike,env.es,ms);
        if(print_details) { printf("mpfr input is NaN -> IEEE-like output set to qNaN\n"); }
    }
    else if(mpfr_inf_p(input_mpfr))
    {
        bool sign_bit = (mpfr_sgn(input_mpfr)>=0 ? 0 : 1);
        IEEElike_set_to_Inf(output_IEEElike,env.es,ms,sign_bit);
        if(print_details) { printf("mpfr input is inf -> IEEE-like output set to Inf with same sign\n"); }
    }
    else if(mpfr_zero_p(input_mpfr))
    {
        //set S field value
        if(result_str[0] == '-')// -0
        {
            SET_BIT_TO_1__DWORD_ARRAY(output_IEEElike,IEEELIKE_S_INDEX(ms,env.es));//S set to 1
        }
        else
        {
            SET_BIT_TO_0__DWORD_ARRAY(output_IEEElike,IEEELIKE_S_INDEX(ms,env.es));//S set to 0
        }
        //set E field value and T field value to 0s
        for(int16_t index_in_IEEElike = IEEELIKE_E_MSB_INDEX(ms,env.es); index_in_IEEElike >= IEEELIKE_T_LSB_INDEX; index_in_IEEElike--)//from MSB of E to LSB of T
        {
            SET_BIT_TO_0__DWORD_ARRAY(output_IEEElike,index_in_IEEElike);
        }
        if(print_details) { printf("mpfr input is zero -> IEEE-like output set to zero with same sign\n"); }
    }
    else
    {

        //round to ms+1 if significand too long
        if( (mpfr_get_prec(input_mpfr) > (MBITS(env)+1)) 
            && (exponent-1 >= IEEElike_emin(env.es)) )
        {
            mpfr_prec_round(input_mpfr,MBITS(env)+1,rounding_mode);
            if(print_details) { printf("the input significand is too long -> rounding applied\n"); }
        }

        //write the MPFR value into a string
        // result_str = mpfr_get_str(NULL,&exponent,2,0,input_mpfr,MPFR_RNDN);//get significand in binary as char array, and exponent

        if(print_details)
        {
            printf("string : %s\n",result_str);
            printf("exponent : %ld\n",exponent);
        }

        //in the char array return by mpfr_get_str, there is an implicit radix point immediately to the left of the first digit
        //so the first bit is ignored (hidden bit, a gnumber store significand bits after 1.) and the exponent is decremented

        exponent--;//the decimal point will be moved because of the hidden bit

        if(IEEElike_exponent_fits(output_IEEElike, input_mpfr, exponent,env,rounding_mode,print_details))
        {

            uint16_t index_in_trailing_bits = 0;
            uint8_t offset_for_str = 1;//start at the 2nd bit (index 1), hide the leading 1 bit

            if(result_str[0] == '-')//in case of negative number
            {
                SET_BIT_TO_1__DWORD_ARRAY(output_IEEElike,IEEELIKE_S_INDEX(ms,env.es));
                offset_for_str++;
            }
            else
            {
                SET_BIT_TO_0__DWORD_ARRAY(output_IEEElike,IEEELIKE_S_INDEX(ms,env.es));
            }

            //go all over the characters to write T field
            while(result_str[index_in_trailing_bits+offset_for_str] != '\0')//until the end of string
            {
                if(result_str[index_in_trailing_bits+offset_for_str] == '1')
                {
                    SET_BIT_TO_1__DWORD_ARRAY(output_IEEElike,IEEELIKE_T_MSB_INDEX(ms)-index_in_trailing_bits);
                }
                else// if(result_str[index_in_trailing_bits+offset_for_str] == '0') //assume there are ony '1's and '0's
                {
                    SET_BIT_TO_0__DWORD_ARRAY(output_IEEElike,IEEELIKE_T_MSB_INDEX(ms)-index_in_trailing_bits);
                }
                index_in_trailing_bits++;//read next char in next loop
            }

            //fill the remaining of the T field with 0s
            while(index_in_trailing_bits <= (ms-1))//until the (ms)th (index ms-1) bit of significand
            {
                SET_BIT_TO_0__DWORD_ARRAY(output_IEEElike,IEEELIKE_T_MSB_INDEX(ms)-index_in_trailing_bits);
                index_in_trailing_bits++;
            }

            uint64_t E = exponent + IEEElike_emax(env.es);//remove bias
            //write E value
            for(uint16_t index_in_IEEElike = IEEELIKE_E_MSB_INDEX(ms,env.es); index_in_IEEElike >= IEEELIKE_E_LSB_INDEX(ms); index_in_IEEElike--)//from MSB to LSB
            {
                if(GET_BIT__QWORD(E,index_in_IEEElike-IEEELIKE_E_LSB_INDEX(ms)))
                {
                    SET_BIT_TO_1__DWORD_ARRAY(output_IEEElike,index_in_IEEElike);
                }
                else
                {
                    SET_BIT_TO_0__DWORD_ARRAY(output_IEEElike,index_in_IEEElike);
                }
            }
        }
        else
        {
            //underflow/overflow
            //the sign needs to be copied after
            if(mpfr_sgn(input_mpfr)>=0)//if input is positive
            {
                SET_BIT_TO_0__DWORD_ARRAY(output_IEEElike,IEEELIKE_S_INDEX(ms,env.es));
                
                if ((exponent < IEEElike_emin(env.es) - MBITS(env)) && exponent < IEEElike_emin(env.es) && (rounding_mode == MPFR_RNDU) ) {
                   SET_BIT_TO_1__DWORD_ARRAY(output_IEEElike, ms - (MBITS(env)));
                }
            }
            else
            {
                SET_BIT_TO_1__DWORD_ARRAY(output_IEEElike,IEEELIKE_S_INDEX(ms,env.es));
                
                if ((exponent < IEEElike_emin(env.es) - MBITS(env)) && exponent < IEEElike_emin(env.es) && (rounding_mode == MPFR_RNDD) ) {
                    SET_BIT_TO_1__DWORD_ARRAY(output_IEEElike, ms - (MBITS(env)));
                }
            }
            
            if ( (exponent == IEEElike_emin(env.es) - MBITS(env) - 1)) // The hidden bit is at the position LSB-1 of the subnormalized mantissa
            {
                if ((rounding_mode == MPFR_RNDN))
                {
                    int i=1; // Remove hidden bit
                    int is_mantissa_zero = 1;
                    while (result_str[i] !=  '\0')
                    {
                        if (result_str[i] != '0')
                        {
                            is_mantissa_zero = 0;
                        }
                        i++;
                    }
                    if (!is_mantissa_zero)
                    {
                        SET_BIT_TO_1__DWORD_ARRAY(output_IEEElike, ms - (MBITS(env)));
                    }
                } else if (rounding_mode == MPFR_RNDNA )
                {
                    SET_BIT_TO_1__DWORD_ARRAY(output_IEEElike, ms - (MBITS(env)));
                }
            }

        }
        mpfr_free_str(result_str);
    }
    // if(print_details) { printf("IEEE-like output = "); IEEElike_print_value(output_IEEElike,env); putchar('\n'); }
}
