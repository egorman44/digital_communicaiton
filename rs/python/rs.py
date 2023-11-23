#!/usr/bin/env python
# -*- coding: utf-8 -*-

# All code is taken from here:
# https://en.wikiversity.org/wiki/Reed%E2%80%93Solomon_codes_for_coders/Additional_information#Universal_Reed-Solomon_Codec

###################################################
### Universal Reed-Solomon Codec
### initially released at Wikiversity
###################################################

################### INIT and stuff ###################

try: # compatibility with Python 3+
    xrange
except NameError:
    xrange = range

class ReedSolomonError(Exception):
    pass

gf_exp = [0] * 512 # For efficiency, gf_exp[] has size 2*GF_SIZE, so that a simple multiplication of two numbers can be resolved without calling % 255. For more infos on how to generate this extended exponentiation table, see paper: "Fast software implementation of finite field operations", Cheng Huang and Lihao Xu, Washington University in St. Louis, Tech. Rep (2003).
gf_log = [0] * 256
field_charac = int(2**8 - 1)

################### GALOIS FIELD ELEMENTS MATHS ###################

def rwh_primes1(n):
    # http://stackoverflow.com/questions/2068372/fastest-way-to-list-all-primes-below-n-in-python/3035188#3035188
    ''' Returns  a list of primes < n '''
    sieve = [True] * (n/2)
    for i in xrange(3,int(n**0.5)+1,2):
        if sieve[i/2]:
            sieve[i*i/2::i] = [False] * ((n-i*i-1)/(2*i)+1)
    return [2] + [2*i+1 for i in xrange(1,n/2) if sieve[i]]

def find_prime_polys(generator=2, c_exp=8, fast_primes=False, single=False):
    '''Compute the list of prime polynomials for the given generator and galois field characteristic exponent.'''
    # fast_primes will output less results but will be significantly faster.
    # single will output the first prime polynomial found, so if all you want is to just find one prime polynomial to generate the LUT for Reed-Solomon to work, then just use that.

    # A prime polynomial (necessarily irreducible) is necessary to reduce the multiplications in the Galois Field, so as to avoid overflows.
    # Why do we need a "prime polynomial"? Can't we just reduce modulo 255 (for GF(2^8) for example)? Because we need the values to be unique.
    # For example: if the generator (alpha) = 2 and c_exp = 8 (GF(2^8) == GF(256)), then the generated Galois Field (0, 1, a, a^1, a^2, ..., a^(p-1)) will be galois field it becomes 0, 1, 2, 4, 8, 16, etc. However, upon reaching 128, the next value will be doubled (ie, next power of 2), which will give 256. Then we must reduce, because we have overflowed above the maximum value of 255. But, if we modulo 255, this will generate 256 == 1. Then 2, 4, 8, 16, etc. giving us a repeating pattern of numbers. This is very bad, as it's then not anymore a bijection (ie, a non-zero value doesn't have a unique index). That's why we can't just modulo 255, but we need another number above 255, which is called the prime polynomial.
    # Why so much hassle? Because we are using precomputed look-up tables for multiplication: instead of multiplying a*b, we precompute alpha^a, alpha^b and alpha^(a+b), so that we can just use our lookup table at alpha^(a+b) and get our result. But just like in our original field we had 0,1,2,...,p-1 distinct unique values, in our "LUT" field using alpha we must have unique distinct values (we don't care that they are different from the original field as long as they are unique and distinct). That's why we need to avoid duplicated values, and to avoid duplicated values we need to use a prime irreducible polynomial.

    # Here is implemented a bruteforce approach to find all these prime polynomials, by generating every possible prime polynomials (ie, every integers between field_charac+1 and field_charac*2), and then we build the whole Galois Field, and we reject the candidate prime polynomial if it duplicates even one value or if it generates a value above field_charac (ie, cause an overflow).
    # Note that this algorithm is slow if the field is too big (above 12), because it's an exhaustive search algorithm. There are probabilistic approaches, and almost surely prime approaches, but there is no determistic polynomial time algorithm to find irreducible monic polynomials. More info can be found at: http://people.mpi-inf.mpg.de/~csaha/lectures/lec9.pdf
    # Another faster algorithm may be found at Adleman, Leonard M., and Hendrik W. Lenstra. "Finding irreducible polynomials over finite fields." Proceedings of the eighteenth annual ACM symposium on Theory of computing. ACM, 1986.

# Prepare the finite field characteristic (2^p - 1), this also represent the maximum possible value in this field
    root_charac = 2 # we're in GF(2)
    field_charac = int(root_charac**c_exp - 1)
    field_charac_next = int(root_charac**(c_exp+1) - 1)

    prim_candidates = []
    if fast_primes:
        prim_candidates = rwh_primes1(field_charac_next) # generate maybe prime polynomials and check later if they really are irreducible
        prim_candidates = [x for x in prim_candidates if x > field_charac] # filter out too small primes
    else:
        prim_candidates = xrange(field_charac+2, field_charac_next, root_charac) # try each possible prime polynomial, but skip even numbers (because divisible by 2 so necessarily not irreducible)

    # Start of the main loop
    correct_primes = []
    for prim in prim_candidates: # try potential candidates primitive irreducible polys
        seen = [0] * (field_charac+1) # memory variable to indicate if a value was already generated in the field (value at index x is set to 1) or not (set to 0 by default)
        conflict = False # flag to know if there was at least one conflict

        # Second loop, build the whole Galois Field
        x = 1
        for i in xrange(field_charac):
            # Compute the next value in the field (ie, the next power of alpha/generator)
            x = gf_mult_noLUT(x, generator, prim, field_charac+1)

            # Rejection criterion: if the value overflowed (above field_charac) or is a duplicate of a previously generated power of alpha, then we reject this polynomial (not prime)
            if x > field_charac or seen[x] == 1:
                conflict = True
                break
            # Else we flag this value as seen (to maybe detect future duplicates), and we continue onto the next power of alpha
            else:
                seen[x] = 1


        # End of the second loop: if there's no conflict (no overflow nor duplicated value), this is a prime polynomial!
        if not conflict: 
            correct_primes.append(prim)
            if single: return prim

    # Return the list of all prime polynomials
    return correct_primes # you can use the following to print the hexadecimal representation of each prime polynomial: print [hex(i) for i in correct_primes]

def init_tables(prim=0x11d, generator=2, c_exp=8):
    '''Precompute the logarithm and anti-log tables for faster computation later, using the provided primitive polynomial.
    These tables are used for multiplication/division since addition/substraction are simple XOR operations inside GF of characteristic 2.
    The basic idea is quite simple: since b**(log_b(x), log_b(y)) == x * y given any number b (the base or generator of the logarithm), then we can use any number b to precompute logarithm and anti-log (exponentiation) tables to use for multiplying two numbers x and y.
    That's why when we use a different base/generator number, the log and anti-log tables are drastically different, but the resulting computations are the same given any such tables.
    For more infos, see https://en.wikipedia.org/wiki/Finite_field_arithmetic#Implementation_tricks
    '''
    # generator is the generator number (the "increment" that will be used to walk through the field by multiplication, this must be a prime number). This is basically the base of the logarithm/anti-log tables. Also often noted "alpha" in academic books.
    # prim is the primitive/prime (binary) polynomial and must be irreducible (ie, it can't represented as the product of two smaller polynomials). It's a polynomial in the binary sense: each bit is a coefficient, but in fact it's an integer between field_charac+1 and field_charac*2, and not a list of gf values. The prime polynomial will be used to reduce the overflows back into the range of the Galois Field without duplicating values (all values should be unique). See the function find_prime_polys() and: http://research.swtch.com/field and http://www.pclviewer.com/rs2/galois.html
    # note that the choice of generator or prime polynomial doesn't matter very much: any two finite fields of size p^n have identical structure, even if they give the individual elements different names (ie, the coefficients of the codeword will be different, but the final result will be the same: you can always correct as many errors/erasures with any choice for those parameters). That's why it makes sense to refer to all the finite fields, and all decoders based on Reed-Solomon, of size p^n as one concept: GF(p^n). It can however impact sensibly the speed (because some parameters will generate sparser tables).
    # c_exp is the exponent for the field's characteristic GF(2^c_exp)

    global gf_exp, gf_log, field_charac
    field_charac = int(2**c_exp - 1)
    gf_exp = [0] * (field_charac * 2) # anti-log (exponential) table. The first two elements will always be [GF256int(1), generator]
    gf_log = [0] * (field_charac+1) # log table, log[0] is impossible and thus unused

# For each possible value in the galois field 2^8, we will pre-compute the logarithm and anti-logarithm (exponential) of this value
    # To do that, we generate the Galois Field F(2^p) by building a list starting with the element 0 followed by the (p-1) successive powers of the generator a : 1, a, a^1, a^2, ..., a^(p-1).
    x = 1
    for i in xrange(field_charac): # we could skip index 255 which is equal to index 0 because of modulo: g^255==g^0 but either way, this does not change the later outputs (ie, the ecc symbols will be the same either way)
        gf_exp[i] = x # compute anti-log for this value and store it in a table
        gf_log[x] = i # compute log at the same time
        x = gf_mult_noLUT(x, generator, prim, field_charac+1)

        # If you use only generator==2 or a power of 2, you can use the following which is faster than gf_mult_noLUT():
        #x <<= 1 # multiply by 2 (change 1 by another number y to multiply by a power of 2^y)
        #if x & 0x100: # similar to x >= 256, but a lot faster (because 0x100 == 256)
            #x ^= prim # substract the primary polynomial to the current value (instead of 255, so that we get a unique set made of coprime numbers), this is the core of the tables generation

    # Optimization: double the size of the anti-log table so that we don't need to mod 255 to stay inside the bounds (because we will mainly use this table for the multiplication of two GF numbers, no more).
    for i in xrange(field_charac, field_charac * 2):
        gf_exp[i] = gf_exp[i - field_charac]

    return [gf_log, gf_exp]

def gf_sub(x, y):
    return x ^ y # in binary galois field, substraction is just the same as addition (since we mod 2)

def gf_neg(x):
    return x

def gf_mul(x, y):
    if x == 0 or y == 0:
        return 0
    return gf_exp[(gf_log[x] + gf_log[y]) % field_charac]

def gf_div(x, y):
    if y == 0:
        raise ZeroDivisionError()
    if x == 0:
        return 0
    return gf_exp[(gf_log[x] + field_charac - gf_log[y]) % field_charac]

def gf_pow(x, power):
    return gf_exp[(gf_log[x] * power) % field_charac]

def gf_inverse(x):
    return gf_exp[field_charac - gf_log[x]] # gf_inverse(x) == gf_div(1, x)

def gf_mult_noLUT(x, y, prim=0, field_charac_full=256, carryless=True):
    '''Galois Field integer multiplication using Russian Peasant Multiplication algorithm (faster than the standard multiplication + modular reduction).
    If prim is 0 and carryless=False, then the function produces the result for a standard integers multiplication (no carry-less arithmetics nor modular reduction).'''
    r = 0
    while y: # while y is above 0
        if y & 1: r = r ^ x if carryless else r + x # y is odd, then add the corresponding x to r (the sum of all x's corresponding to odd y's will give the final product). Note that since we're in GF(2), the addition is in fact an XOR (very important because in GF(2) the multiplication and additions are carry-less, thus it changes the result!).
        y = y >> 1 # equivalent to y // 2
        x = x << 1 # equivalent to x*2
        if prim > 0 and x & field_charac_full: x = x ^ prim # GF modulo: if x >= 256 then apply modular reduction using the primitive polynomial (we just substract, but since the primitive number can be above 256 then we directly XOR).

    return r

################### GALOIS FIELD POLYNOMIALS MATHS ###################

def gf_poly_scale(p, x):
    return [gf_mul(p[i], x) for i in xrange(len(p))]

def gf_poly_add(p,q):
    r = [0] * max(len(p),len(q))
    for i in xrange(len(p)):
        r[i+len(r)-len(p)] = p[i]
    for i in xrange(len(q)):
        r[i+len(r)-len(q)] ^= q[i]
    return r

def gf_poly_mul(p, q):
    '''Multiply two polynomials, inside Galois Field (but the procedure is generic). Optimized function by precomputation of log.'''
    # Pre-allocate the result array
    r = [0] * (len(p) + len(q) - 1)
    # Precompute the logarithm of p
    lp = [gf_log[p[i]] for i in xrange(len(p))]
    # Compute the polynomial multiplication (just like the outer product of two vectors, we multiply each coefficients of p with all coefficients of q)
    for j in xrange(len(q)):
        qj = q[j] # optimization: load the coefficient once
        if qj != 0: # log(0) is undefined, we need to check that
            lq = gf_log[qj] # Optimization: precache the logarithm of the current coefficient of q
            for i in xrange(len(p)):
                if p[i] != 0: # log(0) is undefined, need to check that...
                    r[i + j] ^= gf_exp[lp[i] + lq] # equivalent to: r[i + j] = gf_add(r[i+j], gf_mul(p[i], q[j]))
    return r

def gf_poly_mul_simple(p, q): # simple equivalent way of multiplying two polynomials without precomputation, but thus it's slower
    '''Multiply two polynomials, inside Galois Field'''
    # Pre-allocate the result array
    r = [0] * (len(p) + len(q) - 1)
    # Compute the polynomial multiplication (just like the outer product of two vectors, we multiply each coefficients of p with all coefficients of q)
    for j in xrange(len(q)):
        for i in xrange(len(p)):
            r[i + j] ^= gf_mul(p[i], q[j]) # equivalent to: r[i + j] = gf_add(r[i+j], gf_mul(p[i], q[j])) -- you can see it's your usual polynomial multiplication
    return r

def gf_poly_neg(poly):
    '''Returns the polynomial with all coefficients negated. In GF(2^p), negation does not change the coefficient, so we return the polynomial as-is.'''
    return poly

def gf_poly_div(dividend, divisor):
    '''Fast polynomial division by using Extended Synthetic Division and optimized for GF(2^p) computations
    (doesn't work with standard polynomials outside of this galois field, see the Wikipedia article for generic algorithm).'''
    # CAUTION: this function expects polynomials to follow the opposite convention at decoding:
    # the terms must go from the biggest to lowest degree (while most other functions here expect
    # a list from lowest to biggest degree). eg: 1 + 2x + 5x^2 = [5, 2, 1], NOT [1, 2, 5]

    msg_out = list(dividend) # Copy the dividend list and pad with 0 where the ecc bytes will be computed
    #normalizer = divisor[0] # precomputing for performance
    for i in xrange(len(dividend) - (len(divisor)-1)):
        #msg_out[i] /= normalizer # for general polynomial division (when polynomials are non-monic), the usual way of using
                                  # synthetic division is to divide the divisor g(x) with its leading coefficient, but not needed here.
        coef = msg_out[i] # precaching
        if coef != 0: # log(0) is undefined, so we need to avoid that case explicitly (and it's also a good optimization).
            for j in xrange(1, len(divisor)): # in synthetic division, we always skip the first coefficient of the divisior,
                                              # because it's only used to normalize the dividend coefficient
                if divisor[j] != 0: # log(0) is undefined
                    msg_out[i + j] ^= gf_mul(divisor[j], coef) # equivalent to the more mathematically correct
                                                               # (but xoring directly is faster): msg_out[i + j] += -divisor[j] * coef

    # The resulting msg_out contains both the quotient and the remainder, the remainder being the size of the divisor
    # (the remainder has necessarily the same degree as the divisor -- not length but degree == length-1 -- since it's
    # what we couldn't divide from the dividend), so we compute the index where this separation is, and return the quotient and remainder.
    separator = -(len(divisor)-1)
    return msg_out[:separator], msg_out[separator:] # return quotient, remainder.

def gf_poly_eval(poly, x):
    '''Evaluates a polynomial in GF(2^p) given the value for x. This is based on Horner's scheme for maximum efficiency.'''
    y = poly[0]
    for i in xrange(1, len(poly)):
        y = gf_mul(y, x) ^ poly[i]
    return y

################## REED-SOLOMON ENCODING ###################

def rs_generator_poly(nsym, fcr=0, generator=2):
    '''Generate an irreducible generator polynomial (necessary to encode a message into Reed-Solomon)'''
    g = [1]
    for i in xrange(nsym):
        g = gf_poly_mul(g, [1, gf_pow(generator, i+fcr)])
    return g

def rs_generator_poly_all(max_nsym, fcr=0, generator=2):
    '''Generate all irreducible generator polynomials up to max_nsym (usually you can use n, the length of the message+ecc). Very useful to reduce processing time if you want to encode using variable schemes and nsym rates.'''
    g_all = {}
    g_all[0] = g_all[1] = [1]
    for nsym in xrange(max_nsym):
        g_all[nsym] = rs_generator_poly(nsym, fcr, generator)
    return g_all

def rs_simple_encode_msg(msg_in, nsym, fcr=0, generator=2, gen=None):
    '''Simple Reed-Solomon encoding (mainly an example for you to understand how it works, because it's slower than the inlined function below)'''
    global field_charac
    if (len(msg_in) + nsym) > field_charac: raise ValueError("Message is too long (%i when max is %i)" % (len(msg_in)+nsym, field_charac))
    if gen is None: gen = rs_generator_poly(nsym, fcr, generator)

    # Pad the message, then divide it by the irreducible generator polynomial
    _, remainder = gf_poly_div(msg_in + [0] * (len(gen)-1), gen)
    # The remainder is our RS code! Just append it to our original message to get our full codeword (this represents a polynomial of max 256 terms)
    msg_out = msg_in + remainder
    # Return the codeword
    return msg_out

def rs_encode_msg(msg_in, nsym, fcr=0, generator=2, gen=None):
    '''Reed-Solomon main encoding function, using polynomial division (Extended Synthetic Division, the fastest algorithm available to my knowledge), better explained at http://research.swtch.com/field'''
    global field_charac
    if (len(msg_in) + nsym) > field_charac: raise ValueError("Message is too long (%i when max is %i)" % (len(msg_in)+nsym, field_charac))
    if gen is None: gen = rs_generator_poly(nsym, fcr, generator)
    # Init msg_out with the values inside msg_in and pad with len(gen)-1 bytes (which is the number of ecc symbols).
    msg_out = [0] * (len(msg_in) + len(gen)-1)
    # Initializing the Synthetic Division with the dividend (= input message polynomial)
    msg_out[:len(msg_in)] = msg_in

    # Synthetic division main loop
    for i in xrange(len(msg_in)):
        # Note that it's msg_out here, not msg_in. Thus, we reuse the updated value at each iteration
        # (this is how Synthetic Division works: instead of storing in a temporary register the intermediate values,
        # we directly commit them to the output).
        coef = msg_out[i]

        # log(0) is undefined, so we need to manually check for this case.
        if coef != 0:
            # in synthetic division, we always skip the first coefficient of the divisior, because it's only used to normalize the dividend coefficient (which is here useless since the divisor, the generator polynomial, is always monic)
            for j in xrange(1, len(gen)):
                #if gen[j] != 0: # log(0) is undefined so we need to check that, but it slow things down in fact and it's useless in our case (reed-solomon encoding) since we know that all coefficients in the generator are not 0
                msg_out[i+j] ^= gf_mul(gen[j], coef) # equivalent to msg_out[i+j] += gf_mul(gen[j], coef)

    # At this point, the Extended Synthetic Divison is done, msg_out contains the quotient in msg_out[:len(msg_in)]
    # and the remainder in msg_out[len(msg_in):]. Here for RS encoding, we don't need the quotient but only the remainder
    # (which represents the RS code), so we can just overwrite the quotient with the input message, so that we get
    # our complete codeword composed of the message + code.
    msg_out[:len(msg_in)] = msg_in

    return msg_out    

################### REED-SOLOMON DECODING ###################

def rs_calc_syndromes(msg, nsym, fcr=0, generator=2):
    '''Given the received codeword msg and the number of error correcting symbols (nsym), computes the syndromes polynomial.
    Mathematically, it's essentially equivalent to a Fourrier Transform (Chien search being the inverse).
    '''
    # Note the "[0] +" : we add a 0 coefficient for the lowest degree (the constant). This effectively shifts the syndrome, and will shift every computations depending on the syndromes (such as the errors locator polynomial, errors evaluator polynomial, etc. but not the errors positions).
    # This is not necessary, you can adapt subsequent computations to start from 0 instead of skipping the first iteration (ie, the often seen range(1, n-k+1)),
    synd = [0] * nsym
    for i in xrange(nsym):
        synd[i] = gf_poly_eval(msg, gf_pow(generator, i+fcr))
    return [0] + synd # pad with one 0 for mathematical precision (else we can end up with weird calculations sometimes)


