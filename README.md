# TP-01-IA
Trabalho 01 IA - 01/05

### Questão 3
1. Sf_1
    1. `move(a, pos(3, 0), pos(1, 1))`
    2. `move(b, pos(5, 0), pos(1, 2))`
        1. `apply_gravity()`
            Blocos afetados
                `on(d, pos(3, 0))`
    3. `move(b, pos(1, 2), pos(5, 1))`
    4. `move(a, pos(1,1), pos(4, 1))`
    5. `move(c, pos(0, 0), pos(4,2))`

2. Sf_2
    1. `move(a, pos(3, 0), pos(2, 0))`
    2. `move(d, pos(3, 1), pos(1, 1))`
    3. `move(b, pos(5, 0), pos(0, 1))`
    4. `move(d, pos(1, 1), pos(3, 0))`
    5. `move(b, pos(0, 1), pos(2, 1))`
    6. `move(c, pos(0, 0), pos(4, 1))`
    7. `move(b, pos(2, 1), pos(5, 2))`
    8. `move(a, pos(2, 0), pos(4, 2))`
3. Sf_3
    1. `move(a, pos(2,0), pos(3,0))`
    2. `move(d, pos(0,1), pos(3,1))`
4. Sf_4
    1. `move(a, pos(3, 0), pos(0, 1))`
    2. `move(b, pos(5,0), pos(1, 1))`
        1. `apply_gravity()`
           Blocos afetados
               `on(d, pos(3, 0))`
    3. `move(d, pos(3, 0), pos(2, 0))`
    4. `move(b, pos(1, 1), pos(5, 0))`


Situação 2
1. `move(b, pos(1, 1), pos(2, 0))`
2. `move(a, pos(0, 1), pos(2, 1))`
3. `move(c, pos(0, 0), pos(4, 1))`
4. `move(a, pos(2, 1), pos(4, 2))`
5. `move(b, pos(2, 0), pos(5, 2))`
    

Situação 3
1. `move(d, pos(3, 1), pos(0, 1))`
2. `move(a, pos(3, 0), pos(5, 1))`
3. `move(d, pos(0, 1), pos(2, 0))`
4. `move(a, pos(5, 1), pos(0, 1))`
5. `move(b, pos(5, 0), pos(1, 1))`
6. -
7. `move(d, pos(2, 0), pos(3, 0))`


### Questão 5
- Situação 1
    - Sf1:
    - Sf2: 
    - Sf3: `S = [at(a, 3, 0), at(b, 5, 0), at(c, 0, 0), at(d, 3, 1)],
Plan = [move(d, pos(3, 1), pos(0, 1)), move(a, pos(3, 0), pos(2, 0))].`
    - Sf4: `S = [at(a, 3, 0), at(b, 5, 0), at(c, 0, 0), at(d, 3, 1)],
Plan = [move(d, pos(3, 1), pos(0, 1)), move(a, pos(3, 0), pos(5, 1)), move(d, pos(0, 1), pos(2, 0)), move(a, pos(5, 1), pos(0, 1))].`
- Situação 2: `S = [at(a, 0, 1), at(b, 1, 1), at(c, 0, 0), at(d, 3, 0)],
Plan = [move(a, pos(0, 1), pos(2, 0)), move(b, pos(1, 1), pos(2, 1)), move(c, pos(0, 0), pos(4, 1)), move(b, pos(2, 1), pos(5, 2)), move(a, pos(2, 0), pos(4, 2))].`
- Situação 3: 

