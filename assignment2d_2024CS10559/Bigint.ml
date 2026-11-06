module type BIGNUM = sig
    type bigint
    type myBool
    type sign = Neg|NonNeg
    exception DivisionByZero
    val greater_than : bigint -> bigint -> myBool
    val equal : bigint -> bigint -> myBool
    val less_than : bigint -> bigint -> myBool
    val great_or_equal : bigint -> bigint -> myBool
    val less_or_equal : bigint -> bigint -> myBool
    val unary_negation : bigint -> bigint
    val abs : bigint -> bigint
    val add : bigint -> bigint -> bigint
    val subtract : bigint -> bigint -> bigint
    val multiply : bigint -> bigint -> bigint
    val quotient : bigint -> bigint -> bigint
    val remainder : bigint -> bigint -> bigint
    val int_to_bigint : int -> bigint
    val pretty_print : bigint -> string
end

module BigInt : BIGNUM = struct
type bigint = sign * int list
and sign = Neg|NonNeg
type myBool = T | F
exception DivisionByZero

let rec strip x = 
    match x with
    | [] -> [0]
    | 0::hs -> strip hs
    | hs -> hs

let greater_than a b = 
    match a, b with
    | (Neg, _), (NonNeg,_) -> F
    | (NonNeg, _), (Neg, _) -> T
    | (Neg, x), (Neg, y) -> if List.length x > List.length y then F else if List.length x < List.length y then T else 
    let rec compare_helper x y = 
    match x, y with
    | [], [] -> F
    | [], g::gs -> failwith "should not have come to this point"
    | h::hs, [] -> failwith "should not have come to this point"
    | h::hs, g::gs -> if h > g then F else if h < g then T else compare_helper hs gs
    in compare_helper x y
    | (NonNeg, x), (NonNeg, y) -> if List.length x > List.length y then T else if List.length x < List.length y then F else 
    let rec compare_helper x y = 
    match x, y with
    | [], [] -> F
    | [], g::gs -> failwith "should not have come to this point"
    | h::hs, [] -> failwith "should not have come to this point"
    | h::hs, g::gs -> if h > g then T else if h < g then F else compare_helper hs gs
    in compare_helper x y

let equal a b = 
    match a, b with
    | (Neg, _), (NonNeg, _) -> F
    | (NonNeg, _), (Neg, _) -> F
    | (Neg, x), (Neg, y) -> if List.length x > List.length y || List.length x < List.length y then F else 
    let rec compare_helper x y = 
    match x, y with
    | [], [] -> T
    | [], g::gs -> F
    | h::hs, [] -> F
    | h::hs, g::gs -> if h > g || h < g then F else compare_helper hs gs
    in compare_helper x y
    | (NonNeg, x), (NonNeg, y) -> if List.length x > List.length y || List.length x < List.length y then F else 
    let rec compare_helper x y = 
    match x, y with
    | [], [] -> T
    | [], g::gs -> F
    | h::hs, [] -> F
    | h::hs, g::gs -> if h > g || h < g then F else compare_helper hs gs
    in compare_helper x y

let less_than a b = 
    let gt = greater_than a b in
    let eq = equal a b in
    match gt, eq with
    | T, _ -> F
    | F, T -> F
    | F, F -> T

let great_or_equal a b = 
    let gt = greater_than a b in
    let eq = equal a b in
    match gt, eq with
    | T, _ -> T
    | F, T -> T
    | F, F -> F

let less_or_equal a b = 
    let gt = greater_than a b in
    let eq = equal a b in
    match gt, eq with
    | T, _ -> F
    | F, T -> T
    | F, F -> T

let unary_negation a = 
    match a with 
    | (NonNeg, [0])-> (NonNeg, [0])
    | (Neg, x) -> (NonNeg, x)
    | (NonNeg, x) -> (Neg, x)

let abs a = 
    match a with
    | (Neg, x) -> (NonNeg, x)
    | (NonNeg, x) -> (NonNeg, x)

let rec add_helper x y carry res = (*takes reversed lists as input, gives straight list*)
    match x, y with
    | [], [] -> if carry = 0 then res else carry :: res
    | [], g::gs -> let sum = g+carry in 
    let new_carry = sum / 10 in 
    let p = sum mod 10 in add_helper [] gs new_carry (p::res)
    | h::hs, [] -> let sum = h+carry in 
    let new_carry = sum / 10 in
    let p = sum mod 10 in add_helper hs [] new_carry (p::res)
    | h::hs, g::gs -> let sum = h + g + carry in 
    let new_carry = sum/10 in 
    let p = sum mod 10 in add_helper hs gs new_carry (p::res)

let add_pos x y =
    let x = List.rev x in
    let y = List.rev y in add_helper x y 0 []


let sub x y = (*let x >0, y>=0, x>y always*) (*assume lists to be reversed*)
    let rec sub_helper x y borrow res = 
        match x, y with
        | [],[] -> if borrow = 0 then res else failwith "wrong input"
        | [], g::gs -> failwith "wrong input"
        | h::hs, [] -> if h >= borrow then let p = h - borrow in sub_helper hs [] 0 (p::res) else let p = 10 + h - borrow in sub_helper hs [] 1 (p::res);
        | h::hs, g::gs -> if h >= g+ borrow then let p = h - g - borrow in sub_helper hs gs 0 (p::res) else let p = 10 + h - g - borrow in sub_helper hs gs 1 (p::res)
    in sub_helper x y 0 [] (* ans should be in the correct order now*)

let subtract a b =
    match a,b with
    | (Neg, x), (Neg, y) -> if great_or_equal (Neg, x) (Neg, y)= T then (NonNeg, strip (sub (List.rev y) (List.rev x))) else (Neg, strip (sub (List.rev x) (List.rev y)))
    | (NonNeg, x), (NonNeg, y) -> if great_or_equal (NonNeg, x) (NonNeg, y) = T then (NonNeg, strip (sub (List.rev x) (List.rev y))) else (Neg, strip (sub (List.rev y) (List.rev x)))
    | (Neg, x), (NonNeg, y) -> (Neg, strip (add_pos x y))
    | (NonNeg, x), (Neg, y) -> (NonNeg, strip (add_pos x y))

let add a b = 
    match a,b with
    | (Neg, x), (Neg, y) -> (Neg, strip (add_pos x y))
    | (NonNeg, x), (NonNeg, y) -> (NonNeg, strip (add_pos x y))
    | (Neg, x), (NonNeg, y) -> subtract (NonNeg, y) (unary_negation(Neg, x))
    | (NonNeg, x), (Neg, y) -> subtract (NonNeg, x) (unary_negation(Neg, y))

let rec mult_helper x y carry res = (* here do with y being single digit*)
    match x with
    | [] -> if carry = 0 then res else carry :: res
    | h::hs -> let temp = h*y + carry in let new_carry = temp/10 in let p = temp - new_carry*10 
    in mult_helper hs y new_carry (p::res) (* temp is in normal order *)

let rec mult x y final_res = (* this multiplies x with the digits of y*)
    (* here x is inputted as reversed list, y is straight, is multiplied msd first and each time reversed, 
    consed with a 0 and added with the current reversed multiplied number*)
    match y with
    | [] -> final_res
    | h::hs -> let temp = mult_helper x h 0 [] in let temp_rev = List.rev temp in 
      let curr = add_helper (0::final_res) temp_rev 0 [] in let curr_res = List.rev curr in mult x hs curr_res

let multiply a b = 
    match a, b with
    | (Neg, x), (Neg, y) -> (NonNeg, strip (List. rev (mult (List.rev x)  y [])))
    | (NonNeg, x), (NonNeg, y) -> (NonNeg, strip (List.rev (mult (List.rev x) y [])))
    | (Neg, x), (NonNeg, y) -> if y = [0] then (NonNeg, [0]) else (Neg, strip (List.rev(mult (List.rev x) y [])))
    | (NonNeg, x), (Neg, y) -> if x = [0] then (NonNeg, [0]) else (Neg, strip (List.rev (mult (List.rev x) y [])))

let great_or_equal_helper x y = (*this just checks between lists of numbers*)
    let x_stripped = strip x in
    let y_stripped = strip y in
    let rec check a b = 
        if List.length a > List.length b then T
        else if List.length a < List.length b then F
        else match a, b with
        | [], [] -> T
        | h::hs, g::gs -> if h > g then T else if h < g then F else check hs gs
        | _, _ -> T
    in check x_stripped y_stripped

let rec quotient_helper x y curr count quo = (*the logic of this is simple, while the current part of the dividend, 
like the first some digits are greater than the disisor, subtract divisoor and increment count, and when it gets lesser, 
then extend the current number of digits to involve more digits, and put the digit of the count into the quotient*)
    match x with
    |[]-> if (great_or_equal_helper curr y) = T then quotient_helper x y (strip (sub (List.rev curr) (List.rev y))) (count + 1) quo else List.rev (count :: quo)
    |h::hs -> if great_or_equal_helper curr y = T  then quotient_helper x y (strip (sub (List.rev curr) (List.rev y))) (count + 1) quo
    else quotient_helper hs y (strip (curr@[h])) 0 (count::quo)

let quot x y = 
    match y with 
    | [0] -> raise DivisionByZero
    | gs -> quotient_helper x y [] 0 []
(* quotient is negative if the signs disagree*)

let quotient a b = 
    match a, b with
    | (Neg, x), (Neg, y) -> (NonNeg, strip(quot x y))
    | (NonNeg, x), (NonNeg, y) -> (NonNeg, strip(quot x y))
    | (Neg, x), (NonNeg, y) -> (Neg, strip(quot x y))
    | (NonNeg, x), (Neg, y) -> if (strip(quot x y)) = [0] then (NonNeg,[0]) else (Neg, strip(quot x y))

let remainder a b = 
    let q = quotient a b in
    subtract a (multiply q b)

let int_to_bigint n =
    let rec int_to_list n e = 
        if n = 0 then [0] else (n mod 10):: (int_to_list (n/10) (e+1))
    in if n >= 0 then (NonNeg, strip(List.rev (int_to_list n 0))) else (Neg, strip(List.rev (int_to_list (-n) 0)))


let pretty_print a =
    match a with 
    | (Neg, x) -> List.fold_left (fun e h -> e ^ (string_of_int h)) "-" x 
    | (NonNeg, x) -> List.fold_left (fun e h -> e ^ (string_of_int h)) "" x

end
