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
 *  Authors       : Sebastien Mestrallet
 *  Creation Date : March, 2025
 *  Description   : bitwise operations
 *  History       :
 */

#ifndef BITWISE_H_INCLUDED
#define BITWISE_H_INCLUDED

#include <stdio.h>
#include <stdarg.h>
#include <cstdint>
#include <algorithm>//for std::min()

// Naming used :
// 64-bits chunk of data (like in hardware) = qword
// 32-bits chunk of data (array width in the model) = dword

//########## MASKING ###################################################################################################

#define AND_MASK__DWORD(index_of_1) (uint32_t(1) << (index_of_1)) /**< create a (32-bits) dword mask filled with 0s, except a 1 at index_of_1 */
#define AND_MASK__QWORD(index_of_1) (uint64_t(1) << (index_of_1)) /**< create a (64-bits) qword mask filled with 0s, except a 1 at index_of_1 */

#define OR_MASK__DWORD(index_of_0) (~(uint32_t(1) << (index_of_0))) /**< create a (32-bits) mask filled with 1s, except a 0 at index_of_0 */
#define OR_MASK__QWORD(index_of_0) (~(uint64_t(1) << (index_of_0))) /**< create a (64-bits) mask filled with 1s, except a 0 at index_of_0 */

//########## BIT READING ###############################################################################################

#define GET_BIT__DWORD(dword,index_of_bit) (((dword) & AND_MASK__DWORD(index_of_bit)) >> (index_of_bit)) /**< access, in the (32-bits) dword, the bit value at index index_of_bit */
#define GET_BIT__QWORD(qword,index_of_bit) (((qword) & AND_MASK__QWORD(index_of_bit)) >> (index_of_bit)) /**< access, in the (64-bits) qword, the bit value at index index_of_bit */

//########## BIT WRITING ###############################################################################################

#define SET_BIT_TO_1__DWORD(dword,index_of_bit) ((dword) |= AND_MASK__DWORD(index_of_bit)) /**< in the (32-bits) dword, set to 1 the bit at index_of_bit */
#define SET_BIT_TO_1__QWORD(qword,index_of_bit) ((qword) |= AND_MASK__QWORD(index_of_bit)) /**< in the (64-bits) qword, set to 1 the bit at index_of_bit */

#define SET_BIT_TO_0__DWORD(dword,index_of_bit) ((dword) &= OR_MASK__DWORD(index_of_bit)) /**< in the (32-bits) dword, set to 0 the bit at index_of_bit */
#define SET_BIT_TO_0__QWORD(qword,index_of_bit) ((qword) &= OR_MASK__QWORD(index_of_bit)) /**< in the (64-bits) qword, set to 0 the bit at index_of_bit */

//########## BIT MANIPULATION INSIDE ARRAYS ############################################################################

#define GET_BIT__DWORD_ARRAY(dword_array,overall_index) (GET_BIT__DWORD(*((dword_array)+(overall_index)/32),(overall_index)%32)) /**< get the bit at overall index in (32-bits) dword array */
#define SET_BIT_TO_1__DWORD_ARRAY(dword_array,overall_index) (SET_BIT_TO_1__DWORD(*((dword_array)+(overall_index)/32),(overall_index)%32)) /**< set to 1 the bit at overall index in (32-bits) dword array */
#define SET_BIT_TO_0__DWORD_ARRAY(dword_array,overall_index) (SET_BIT_TO_0__DWORD(*((dword_array)+(overall_index)/32),(overall_index)%32)) /**< set to 0 the bit at overall index in (32-bits) dword array */

//########## QWORD SEGMENTATION ########################################################################################

#define GET_LEFT_DWORD(dword_array,qword_index) (*((dword_array)+2*(qword_index)+1)) /**< in the (64-bits) qword array indexing, get the index of the left (32-bits) dword */
#define GET_RIGHT_DWORD(dword_array,qword_index) (*((dword_array)+2*(qword_index))) /**< in the (64-bits) qword array indexing, get the index of the right (32-bits) dword */

//########## QWORD ARRAY ###############################################################################################

#define ASSEMBLE_QWORD_FROM_DWORDS(left_dword,right_dword) ((((uint64_t)(left_dword))<<32) + right_dword) /**< knowing the left part and the right part of a qword, return the qword value */
#define GET_QWORD__DWORD_ARRAY(dword_array,qword_index) (ASSEMBLE_QWORD_FROM_DWORDS(GET_LEFT_DWORD(dword_array,qword_index),GET_RIGHT_DWORD(dword_array,qword_index))) /**< knowing the qword index of a dword array, return the qword value like it was a qword array */

//########## BINARY PRINTING ###########################################################################################

/**
 * \brief   Print a integer in binary
 * \details Read and print each bit of \e number. No end of line after.
 * \tparam  T                   Template parameter
 * \param   number              The number to print
 * \param   max_number_of_bits  The number of bits to print. Used to hide leading bits. If zero (default), set to the bit size of T
 * \param   space_out_bytes     If true, a space will be printed between bytes
 * \param   space_padding       If 0, no left-padding. Else print spaces, so the bit are aligned with a \e space_padding bits number
 */
template <typename T>
void print_in_binary(const T number, uint8_t max_number_of_bits = 0, bool space_out_bytes = true, uint8_t space_padding = 0)
{
    max_number_of_bits = (max_number_of_bits == 0 ) ? 8*sizeof(number) : std::min<uint8_t>(max_number_of_bits,8*sizeof(number));//max_number_of_bits should not exceed the bit size of number

    if(space_padding != 0)//if asked for a left space padding, to have space_padding bits overall
    {
        for(signed char j = space_padding-1; j >= max_number_of_bits; j--)
        {
            putchar(' ');
            if(space_out_bytes && j%8==0 && j!=0) { putchar(' '); }//print space between bytes
        }
    }

    for(signed char j = max_number_of_bits-1; j >= 0; j--)//from highest to lowest index
    {
        printf("%u",(bool) GET_BIT__QWORD(number,j));//print bit value
        if(space_out_bytes && j%8==0 && j!=0) { putchar(' '); }//print space between bytes
    }
}

#endif //BITWISE_H_INCLUDED