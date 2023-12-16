from rs import init_tables
from rs import rs_calc_syndromes
from rs import gf_mul
from rs import gf_poly_scale
from rs import gf_poly_add
from rs import gf_inverse
#from rs import gf_log
#from rs import gf_exp

# RS(15,7) GF(2^4)
#tbl = init_tables(prim=0x13, generator=2, c_exp=4)
tbl = init_tables()

symb_to_alpha = []
alpha_to_symb = []

print("\n")
for indx in range (len(tbl[0])):
    symb_to_alpha.append(tbl[0][indx])
    print(f"symb_to_alpha[{indx}] = {tbl[0][indx]}")

print("\n")
for indx in range (len(tbl[0])):
    alpha_to_symb.append(tbl[1][indx])
    print(f"alpha_to_symb[{indx}] = {tbl[1][indx]}")

def alpha_to_symb_func(alpha_list):
    symb_list = []
    for item in alpha_list:
        if item is not None:
            symb_list.append(alpha_to_symb[item])
        else:
            symb_list.append(0)
    return symb_list

def symb_to_alpha_func(symb_list):
    alpha_list = []
    for item in symb_list:
        if item:
            alpha_list.append(symb_to_alpha[item])
        else:
            alpha_list.append(None)        
    return alpha_list

def convert_list_to_hex(integer_list):
    dbg = ''
    for item in integer_list:
        dbg += f"0x{item:x} "
    return dbg
        

# Initialization

err_loc = [1]
aux_B = [1]
r = 1
L_r = 0
roots_num = 16

#syndrome_alpha = [6, 9, 7, 3, 6, 4, 0, 3]
#syndrome_symb = alpha_to_symb_func(syndrome_alpha)
syndrome_symb = [49, 110, 65, 49, 230, 174, 199, 238, 146, 159, 118, 7, 125, 86, 185, 138]
# error_locator [68, 110, 69, 111, 62, 136, 151, 1]
print("\n\n\n START ALGO")
print(f"syndrome_symb {syndrome_symb}")

# syndrome_symb [12, 10, 11, 8, 12, 3, 2, 8]
for r in range(1,roots_num+1):
    print(f"\n\tR = {r}\n")
    print(f"L_r = {L_r}")
    delta_symb = 0
    print(f"gf_mul(err_loc, syndrome_symb")
    for j in range(0, L_r+1):
        print(f"gf_mul({err_loc[-(j+1)]}, {syndrome_symb[r - j - 1]}) = {gf_mul(err_loc[-(j+1)], syndrome_symb[r - j - 1])} ")
        delta_symb ^= gf_mul(err_loc[-(j+1)], syndrome_symb[r - j - 1])
    
    print(f"delta[{r}] = 0x{delta_symb:x} / {symb_to_alpha[delta_symb]}")

    if delta_symb:    
        
        if(2*L_r) <= r - 1:
            L_r = r - L_r
            delta_inv = gf_inverse(delta_symb)
            new_aux_B = gf_poly_scale(err_loc, delta_inv)            
        else:
            
            new_aux_B = aux_B + [0]
            
        B_x_X = aux_B + [0]
        delta_x_B = gf_poly_scale(B_x_X, delta_symb)
        err_loc = gf_poly_add(err_loc, delta_x_B)
        err_loc_alpha = symb_to_alpha_func(err_loc)
        aux_B = new_aux_B
    else:
        aux_B = aux_B + [0]

    print(f" B_x_X = [{convert_list_to_hex(B_x_X)}]")
    print(f" delta_x_B = [{convert_list_to_hex(delta_x_B)}]")
    print(f" aux_B = [{convert_list_to_hex(aux_B)}] / {symb_to_alpha_func(aux_B)}")
    print(f" err_loc = [{convert_list_to_hex(err_loc)}] / {err_loc_alpha}")
    print(f" L_r_new = {L_r}")
              
