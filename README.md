# TP-01-IA
Trabalho 01 IA - 03/05

### Questão 1: Modificações na representação
```text
% Descrição do Espaço

% BLOCO
block(Nome, Width, pos(Left, Bottom))
	% (ex) block(a, 1, pos(3, 0))

% MOVIMENTO
% Sem centro de gravidade: o bloco continua em pé se tiver pelo menos um bloco abaixo dele
	% A movimentação do bloco abaixo deveria ser bloqueado?
	% Gravidade: se não tiver nenhum bloco debaixo de um, ele cai
	% check_if_supported: verifica se o bloco está sendo suportado
	% apply_gravity: move para baixo
	
% Movimento horizontal: o bloco pode ser arrastado se estiver espaço livre à direita ou esquerda

% Movimento unitário: só um bloco pode ser movimentado por vez (não pode carregar blocos que estejam em cima)

move(Bloco, pos(X1, Y1), pos(X2, Y2)) % move(Bloco, Initial, Final)
apply_gravity()
```

---
### Questão 2: Ações associadas às modificações

- **Geometria vs. Topologia:** Enquanto a representação original usa relações simbólicas abstratas como `on(Block, From)`, a nova proposta introduz coordenadas cartesianas `pos(Left, Bottom)` e a propriedade física `Width` (largura) para definir o estado.
- **Condição de Desocupação:** No modelo original, o predicado `clear(X)` indica se algo pode ser movido ou se pode receber um bloco. Na nova representação, isso é substituído por cálculos de colisão geométrica e a regra de "movimento unitário", que impede mover blocos com outros sobrepostos.
- **Suporte e Estabilidade:** A relação de suporte original é binária (`on(X, Y)`). Na nova representação, surge o conceito de suporte parcial (um bloco sobre dois) e a necessidade de validar a estabilidade através do termo `check_if_supported`.
- **Física Dinâmica (Gravidade):** O planejador original é determinístico e direto, onde as ações apenas adicionam ou removem relações fixas (`adds`/`deletes`). A nova representação introduz `apply_gravity()`, uma ação que pode gerar efeitos colaterais automáticos (queda) não previstos na lógica de regressão simples do arquivo `fig17_6.pl`.
- **Espaço de Movimentação:** Na versão original, o movimento é um "salto" entre posições ou blocos. Na nova proposta, existe a distinção entre movimento vertical (gravidade) e movimento horizontal (arrastar), exigindo que o espaço lateral esteja livre.
- **Complexidade de Regressão:** O processo de `regress(Goals, Action, RegressedGoals)` no código original apenas manipula listas de fatos. Na nova representação, a regressão exigiria cálculos matemáticos para determinar quais coordenadas anteriores satisfariam as precondições de largura e posição final.
	

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
6. ~
7. `move(d, pos(2, 0), pos(3, 0))`


### Questão 5
1. Situação 1
    1. Sf1: (execução por tempo indefinido)
    2. Sf2: (execução por tempo indefinido)
      
    3. Sf3: `S = [at(a, 3, 0), at(b, 5, 0), at(c, 0, 0), at(d, 3, 1)]`
          1. `move(d, pos(3, 1), pos(0, 1))`
          2. `move(a, pos(3, 0), pos(2, 0))`
      
    4. Sf4: `S = [at(a, 3, 0), at(b, 5, 0), at(c, 0, 0), at(d, 3, 1)]`
          1. `move(d, pos(3, 1), pos(0, 1))`
          2. `move(a, pos(3, 0), pos(5, 1))`
          3. `move(d, pos(0, 1), pos(2, 0))`
          4. `move(a, pos(5, 1), pos(0, 1))`
      
3. Situação 2: `S = [at(a, 0, 1), at(b, 1, 1), at(c, 0, 0), at(d, 3, 0)]`
    1. `move(a, pos(0, 1), pos(2, 0))`
    2. `move(b, pos(1, 1), pos(2, 1))`
    3. `move(c, pos(0, 0), pos(4, 1))`
    4. `move(b, pos(2, 1), pos(5, 2))`
    5. `move(a, pos(2, 0), pos(4, 2))`

4. Situação 3: `S = [at(a, 3, 0), at(b, 5, 0), at(c, 0, 0), at(d, 3, 1)]`
    1. `move(d,pos(3,1),pos(2,1))`
    2. `move(b,pos(5,0),pos(1,1))`
    3. `move(d,pos(2,1),pos(0,2))`
    4. `move(a,pos(3,0),pos(0,1))`
    5. `move(d,pos(0,2),pos(3,0))]`
