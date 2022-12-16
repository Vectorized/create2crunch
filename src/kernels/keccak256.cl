/*
   Copyright 2018 Lip Wee Yeo Amano

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

/**
* Based on the following, with small tweaks and optimizations:
*
* https://github.com/lwYeo/SoliditySHA3Miner/blob/master/SoliditySHA3Miner/
*   Miner/Kernels/OpenCL/sha3KingKernel.cl
*
* Originally modified for openCL processing by lwYeo
*
* Original implementor: David Leon Gil
*
* License: CC0, attribution kindly requested. Blame taken too, but not
* liability.
*/

/******** Keccak-f[1600] (for finding efficient Ethereum addresses) ********/

#define OPENCL_PLATFORM_UNKNOWN 0
#define OPENCL_PLATFORM_AMD   2

#ifndef PLATFORM
# define PLATFORM       OPENCL_PLATFORM_UNKNOWN
#endif

#if PLATFORM == OPENCL_PLATFORM_AMD
# pragma OPENCL EXTENSION   cl_amd_media_ops : enable
#endif

typedef union _nonce_t
{
  ulong   uint64_t;
  uchar   uint8_t[8];
} nonce_t;

#if PLATFORM == OPENCL_PLATFORM_AMD
static inline ulong rol(const ulong x, const uint s)
{
  uint2 output;
  uint2 x2 = as_uint2(x);

  output = (s > 32u) ? amd_bitalign((x2).yx, (x2).xy, 64u - s) : amd_bitalign((x2).xy, (x2).yx, 32u - s);
  return as_ulong(output);
}
#else
#define rol(x, s) (((x) << s) | ((x) >> (64u - s)))
#endif

#if PLATFORM == OPENCL_PLATFORM_AMD
static inline ulong rol1(const ulong x)
{
  uint2 output;
  uint2 x2 = as_uint2(x);

  output = amd_bitalign((x2).xy, (x2).yx, 31u);
  return as_ulong(output);
}
#else
#define rol1(x) (((x) << 1u) | ((x) >> (63u)))
#endif

#define theta() \
b[0] = a[0] ^ a[5] ^ a[10] ^ a[15] ^ a[20]; \
b[1] = a[1] ^ a[6] ^ a[11] ^ a[16] ^ a[21]; \
b[2] = a[2] ^ a[7] ^ a[12] ^ a[17] ^ a[22]; \
b[3] = a[3] ^ a[8] ^ a[13] ^ a[18] ^ a[23]; \
b[4] = a[4] ^ a[9] ^ a[14] ^ a[19] ^ a[24]; \
\
t = b[4] ^ rol1(b[1]); \
a[0] ^= t; \
a[5] ^= t; \
a[10] ^= t; \
a[15] ^= t; \
a[20] ^= t; \
\
t = b[0] ^ rol1(b[2]); \
a[1] ^= t; \
a[6] ^= t; \
a[11] ^= t; \
a[16] ^= t; \
a[21] ^= t; \
\
t = b[1] ^ rol1(b[3]); \
a[2] ^= t; \
a[7] ^= t; \
a[12] ^= t; \
a[17] ^= t; \
a[22] ^= t; \
\
t = b[2] ^ rol1(b[4]); \
a[3] ^= t; \
a[8] ^= t; \
a[13] ^= t; \
a[18] ^= t; \
a[23] ^= t; \
\
t = b[3] ^ rol1(b[0]); \
a[4] ^= t; \
a[9] ^= t; \
a[14] ^= t; \
a[19] ^= t; \
a[24] ^= t;

#define rhoPi() \
t = a[1]; \
b[0] = a[10]; \
a[10] = rol1(t); \
\
t = b[0]; \
b[0] = a[7]; \
a[7] = rol(t, 3); \
\
t = b[0]; \
b[0] = a[11]; \
a[11] = rol(t, 6); \
\
t = b[0]; \
b[0] = a[17]; \
a[17] = rol(t, 10); \
\
t = b[0]; \
b[0] = a[18]; \
a[18] = rol(t, 15); \
\
t = b[0]; \
b[0] = a[3]; \
a[3] = rol(t, 21); \
\
t = b[0]; \
b[0] = a[5]; \
a[5] = rol(t, 28); \
\
t = b[0]; \
b[0] = a[16]; \
a[16] = rol(t, 36); \
\
t = b[0]; \
b[0] = a[8]; \
a[8] = rol(t, 45); \
\
t = b[0]; \
b[0] = a[21]; \
a[21] = rol(t, 55); \
\
t = b[0]; \
b[0] = a[24]; \
a[24] = rol(t, 2); \
\
t = b[0]; \
b[0] = a[4]; \
a[4] = rol(t, 14); \
\
t = b[0]; \
b[0] = a[15]; \
a[15] = rol(t, 27); \
\
t = b[0]; \
b[0] = a[23]; \
a[23] = rol(t, 41); \
\
t = b[0]; \
b[0] = a[19]; \
a[19] = rol(t, 56); \
\
t = b[0]; \
b[0] = a[13]; \
a[13] = rol(t, 8); \
\
t = b[0]; \
b[0] = a[12]; \
a[12] = rol(t, 25); \
\
t = b[0]; \
b[0] = a[2]; \
a[2] = rol(t, 43); \
\
t = b[0]; \
b[0] = a[20]; \
a[20] = rol(t, 62); \
\
t = b[0]; \
b[0] = a[14]; \
a[14] = rol(t, 18); \
\
t = b[0]; \
b[0] = a[22]; \
a[22] = rol(t, 39); \
\
t = b[0]; \
b[0] = a[9]; \
a[9] = rol(t, 61); \
\
t = b[0]; \
b[0] = a[6]; \
a[6] = rol(t, 20); \
\
t = b[0]; \
b[0] = a[1]; \
a[1] = rol(t, 44);

#define chi() \
b[0] = a[0]; \
b[1] = a[1]; \
b[2] = a[2]; \
b[3] = a[3]; \
b[4] = a[4]; \
a[0] = b[0] ^ ((~b[1]) & b[2]); \
a[1] = b[1] ^ ((~b[2]) & b[3]); \
a[2] = b[2] ^ ((~b[3]) & b[4]); \
a[3] = b[3] ^ ((~b[4]) & b[0]); \
a[4] = b[4] ^ ((~b[0]) & b[1]); \
\
b[0] = a[5]; \
b[1] = a[6]; \
b[2] = a[7]; \
b[3] = a[8]; \
b[4] = a[9]; \
a[5] = b[0] ^ ((~b[1]) & b[2]); \
a[6] = b[1] ^ ((~b[2]) & b[3]); \
a[7] = b[2] ^ ((~b[3]) & b[4]); \
a[8] = b[3] ^ ((~b[4]) & b[0]); \
a[9] = b[4] ^ ((~b[0]) & b[1]); \
\
b[0] = a[10]; \
b[1] = a[11]; \
b[2] = a[12]; \
b[3] = a[13]; \
b[4] = a[14]; \
a[10] = b[0] ^ ((~b[1]) & b[2]); \
a[11] = b[1] ^ ((~b[2]) & b[3]); \
a[12] = b[2] ^ ((~b[3]) & b[4]); \
a[13] = b[3] ^ ((~b[4]) & b[0]); \
a[14] = b[4] ^ ((~b[0]) & b[1]); \
\
b[0] = a[15]; \
b[1] = a[16]; \
b[2] = a[17]; \
b[3] = a[18]; \
b[4] = a[19]; \
a[15] = b[0] ^ ((~b[1]) & b[2]); \
a[16] = b[1] ^ ((~b[2]) & b[3]); \
a[17] = b[2] ^ ((~b[3]) & b[4]); \
a[18] = b[3] ^ ((~b[4]) & b[0]); \
a[19] = b[4] ^ ((~b[0]) & b[1]); \
\
b[0] = a[20]; \
b[1] = a[21]; \
b[2] = a[22]; \
b[3] = a[23]; \
b[4] = a[24]; \
a[20] = b[0] ^ ((~b[1]) & b[2]); \
a[21] = b[1] ^ ((~b[2]) & b[3]); \
a[22] = b[2] ^ ((~b[3]) & b[4]); \
a[23] = b[3] ^ ((~b[4]) & b[0]); \
a[24] = b[4] ^ ((~b[0]) & b[1]);

#define iota(x) a[0] ^= x;

#define iteration(x) theta() rhoPi() chi() iota(x)

static inline void keccakf(ulong *a)
{
  ulong b[5];
  ulong t;

  iteration(0x0000000000000001); // iteration 1
  iteration(0x0000000000008082); // iteration 2
  iteration(0x800000000000808a); // iteration 3
  iteration(0x8000000080008000); // iteration 4
  iteration(0x000000000000808b); // iteration 5
  iteration(0x0000000080000001); // iteration 6
  iteration(0x8000000080008081); // iteration 7
  iteration(0x8000000000008009); // iteration 8
  iteration(0x000000000000008a); // iteration 9
  iteration(0x0000000000000088); // iteration 10
  iteration(0x0000000080008009); // iteration 11
  iteration(0x000000008000000a); // iteration 12
  iteration(0x000000008000808b); // iteration 13
  iteration(0x800000000000008b); // iteration 14
  iteration(0x8000000000008089); // iteration 15
  iteration(0x8000000000008003); // iteration 16
  iteration(0x8000000000008002); // iteration 17
  iteration(0x8000000000000080); // iteration 18
  iteration(0x000000000000800a); // iteration 19
  iteration(0x800000008000000a); // iteration 20
  iteration(0x8000000080008081); // iteration 21
  iteration(0x8000000000008080); // iteration 22
  iteration(0x0000000080000001); // iteration 23
  
  // iteration 24 (partial)

  // Theta (partial)
  b[0] = a[0] ^ a[5] ^ a[10] ^ a[15] ^ a[20];
  b[1] = a[1] ^ a[6] ^ a[11] ^ a[16] ^ a[21];
  b[2] = a[2] ^ a[7] ^ a[12] ^ a[17] ^ a[22];
  b[3] = a[3] ^ a[8] ^ a[13] ^ a[18] ^ a[23];
  b[4] = a[4] ^ a[9] ^ a[14] ^ a[19] ^ a[24];

  a[0] ^= b[4] ^ rol1(b[1]);
  a[1] ^= b[0] ^ rol1(b[2]);
  a[2] ^= b[1] ^ rol1(b[3]);
  a[3] ^= b[2] ^ rol1(b[4]);
  a[4] ^= b[3] ^ rol1(b[0]);
  a[6] ^= b[0] ^ rol1(b[2]);
  a[12] ^= b[1] ^ rol1(b[3]);
  a[18] ^= b[2] ^ rol1(b[4]);
  a[24] ^= b[3] ^ rol1(b[0]);

  // Rho Pi (partial)

  a[1] = rol(a[6], 44);
  a[2] = rol(a[12], 43);
  a[3] = rol(a[18], 21);
  a[4] = rol(a[24], 14);

  // Chi (partial)
  a[1] ^= ((~a[2]) & a[3]);
  a[2] ^= ((~a[3]) & a[4]);
  a[3] ^= ((~a[4]) & a[0]);
}

#define hasTotal(digest) ( \
  (digest[0] == 0x00) + (digest[1] == 0x00) + (digest[2] == 0x00) + (digest[3] == 0x00) + \
  (digest[4] == 0x00) + (digest[5] == 0x00) + (digest[6] == 0x00) + (digest[7] == 0x00) + \
  (digest[8] == 0x00) + (digest[9] == 0x00) + (digest[10] == 0x00) + (digest[11] == 0x00) + \
  (digest[12] == 0x00) + (digest[13] == 0x00) + (digest[14] == 0x00) + (digest[15] == 0x00) + \
  (digest[16] == 0x00) + (digest[17] == 0x00) + (digest[18] == 0x00) + (digest[19] == 0x00) \
>= TOTAL_ZEROES)

#if LEADING_ZEROES == 6
#define hasLeading(left) ((((uint*)left)[0] | left[4] | left[5]) == 0)
#elif LEADING_ZEROES == 5
#define hasLeading(left) ((((uint*)left)[0] | left[4]) == 0)
#elif LEADING_ZEROES == 4
#define hasLeading(left) ((((uint*)left)[0]) == 0)
#elif LEADING_ZEROES == 3
#define hasLeading(left) ((left[0] | left[1] | left[2]) == 0)
#elif LEADING_ZEROES == 2
#define hasLeading(left) ((left[0] | left[1]) == 0)
#elif LEADING_ZEROES == 1
#define hasLeading(left) ((left[0]) == 0)
#else
static inline bool hasLeading(uchar const *left)
{
#pragma unroll
  for (int i = 0; i < LEADING_ZEROES; ++i) {
    if (left[i] != 0) return false;
  }
  return true;
}
#endif

__kernel void hashMessage(
  __constant uchar const *d_message,
  __constant ulong const *d_nonce,
  __global volatile ulong *restrict solutions
) {
  
  ulong spongeBuffer[25];

#define sponge ((uchar *) spongeBuffer)
#define digest (sponge + 12)

  nonce_t nonce;

  // write the control character
  sponge[0] = 0xffu;

  sponge[1] = S_1;
  sponge[2] = S_2;
  sponge[3] = S_3;
  sponge[4] = S_4;
  sponge[5] = S_5;
  sponge[6] = S_6;
  sponge[7] = S_7;
  sponge[8] = S_8;
  sponge[9] = S_9;
  sponge[10] = S_10;
  sponge[11] = S_11;
  sponge[12] = S_12;
  sponge[13] = S_13;
  sponge[14] = S_14;
  sponge[15] = S_15;
  sponge[16] = S_16;
  sponge[17] = S_17;
  sponge[18] = S_18;
  sponge[19] = S_19;
  sponge[20] = S_20;
  sponge[21] = S_21;
  sponge[22] = S_22;
  sponge[23] = S_23;
  sponge[24] = S_24;
  sponge[25] = S_25;
  sponge[26] = S_26;
  sponge[27] = S_27;
  sponge[28] = S_28;
  sponge[29] = S_29;
  sponge[30] = S_30;
  sponge[31] = S_31;
  sponge[32] = S_32;
  sponge[33] = S_33;
  sponge[34] = S_34;
  sponge[35] = S_35;
  sponge[36] = S_36;
  sponge[37] = S_37;
  sponge[38] = S_38;
  sponge[39] = S_39;
  sponge[40] = S_40;

  sponge[41] = d_message[0];
  sponge[42] = d_message[1];
  sponge[43] = d_message[2];
  sponge[44] = d_message[3];

  // populate the nonce
  nonce.uint64_t = get_global_id(0) + d_nonce[0];

  // populate the body of the message with the nonce
  sponge[45] = nonce.uint8_t[0];
  sponge[46] = nonce.uint8_t[1];
  sponge[47] = nonce.uint8_t[2];
  sponge[48] = nonce.uint8_t[3];
  sponge[49] = nonce.uint8_t[4];
  sponge[50] = nonce.uint8_t[5];
  sponge[51] = nonce.uint8_t[6];
  sponge[52] = nonce.uint8_t[7];

  sponge[53] = S_53;
  sponge[54] = S_54;
  sponge[55] = S_55;
  sponge[56] = S_56;
  sponge[57] = S_57;
  sponge[58] = S_58;
  sponge[59] = S_59;
  sponge[60] = S_60;
  sponge[61] = S_61;
  sponge[62] = S_62;
  sponge[63] = S_63;
  sponge[64] = S_64;
  sponge[65] = S_65;
  sponge[66] = S_66;
  sponge[67] = S_67;
  sponge[68] = S_68;
  sponge[69] = S_69;
  sponge[70] = S_70;
  sponge[71] = S_71;
  sponge[72] = S_72;
  sponge[73] = S_73;
  sponge[74] = S_74;
  sponge[75] = S_75;
  sponge[76] = S_76;
  sponge[77] = S_77;
  sponge[78] = S_78;
  sponge[79] = S_79;
  sponge[80] = S_80;
  sponge[81] = S_81;
  sponge[82] = S_82;
  sponge[83] = S_83;
  sponge[84] = S_84;

  // begin padding based on message length
  sponge[85] = 0x01u;

  // fill padding
#pragma unroll
  for (int i = 86; i < 135; ++i)
    sponge[i] = 0;

  // end padding
  sponge[135] = 0x80u;

  // fill remaining sponge state with zeroes
#pragma unroll
  for (int i = 136; i < 200; ++i)
    sponge[i] = 0;

  // Apply keccakf
  keccakf(spongeBuffer);

  // determine if the address meets the constraints
  if (
    hasLeading(digest)
#if TOTAL_ZEROES <= 20
    || hasTotal(digest)
#endif
  ) {
    // To be honest, if we are using OpenCL, 
    // we just need to write one solution for all practical purposes,
    // since the chance of multiple solutions appearing
    // in a single workset is extremely low.
    solutions[0] = nonce.uint64_t;
  }
}
