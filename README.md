# TP-01-IA
Trabalho 01 IA - 03/05
Grupo:
	- Amanda Spellen
	- Jaide Zardin
	- Lucas Darcio

### Questão 1: Modificações na representação

A proposta expandiria a visão para um espaço bidimensional delimitado em um grid. A representação do estado passaria a definir a ocupação espacial exata de cada elemento. Para isso, o sistema adotaria a estrutura `block(Nome, Width, pos(Left, Bottom))`, na qual a largura e as coordenadas cartesianas determinariam o espaço físico ocupado.

Nesse cenário, a lógica de suporte mudaria. Na versão sem o cálculo do centro de gravidade, um bloco se manteria em pé e estável desde que houvesse pelo menos uma unidade de sobreposição com qualquer bloco posicionado exatamente um nível abaixo dele. Para modelar as consequências físicas de um mundo com lacunas, o sistema implementaria uma mecânica de gravidade. Sempre que a verificação check_if_supported indicasse que uma peça perdeu seu apoio, a função `apply_gravity()` deslocaria o bloco iterativamente para baixo até que ele encontrasse uma nova base ou atingisse o chão.

As regras de transição de estado também ganhariam novas restrições. O deslocamento passaria a contemplar o movimento horizontal, o que permitiria que um bloco fosse arrastado para os lados desde que houvesse células livres na direção desejada. O sistema manteria a restrição de movimento unitário: apenas um bloco poderia ser movimentado por vez na ação `move(Bloco, pos(X1, Y1), pos(X2, Y2))`.`

```prolog
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

Sobre a questão do centro de gravidade que não foi implementado na versão final, a ideia que tivemos para modelar tal conhecimento exigiria uma validação física mais rigorosa para o equilíbrio das peças. O sistema calcularia o centro de gravidade horizontal do bloco superior. Matematicamente, a equação seria definida como CG_x = Left + (Width / 2). Semanticamente, essa fórmula representaria o ponto exato de concentração de massa do bloco ao longo do eixo horizontal, assumindo uma distribuição uniforme de peso e densidade em toda a sua extensão.

Em seguida, o planejador identificaria todos os blocos de suporte posicionados diretamente abaixo e determinaria os limites extremos dessa base consolidada, ou seja, a menor coordenada à esquerda e a maior coordenada à direita. Para que a configuração fosse considerada estável, o valor de CG_x deveria estar estritamente contido dentro desses limites. Caso o centro de massa ultrapassasse a base de apoio, a estrutura seria classificada como instável e a transição de estado correspondente seria imediatamente bloqueada pelo sistema.

A lógica algorítmica dessa verificação seguiria possivelmente a seguinte estrutura (revisada com IA):
```prolog
% 1. Condição trivial: blocos no chão sempre seriam estáveis
verificar_estabilidade_geometrica(_, _, 0, _) :- !.

% Predicado principal que validaria o centro de massa para blocos acima do chão
verificar_estabilidade_geometrica(Bloco, NovoX, NovoY, EstadoFuturo) :-
    NovoY > 0,
    block_width(Bloco, Largura),
    
    % 2. Calcularia o Centro de Gravidade (CG) horizontal
    % A equação representaria o ponto de equilíbrio perfeito da peça
    CG_X is NovoX + (Largura / 2.0),
    
    % 3. Identificaria as bases de apoio no estado projetado
    AbaixoY is NovoY - 1,
    
    % Buscaria blocos exatamente 1 nível abaixo que tivessem sobreposição horizontal
    findall(limites(Esq, Dir),
            ( member(at(OutroBloco, Esq, AbaixoY), EstadoFuturo),
              block_width(OutroBloco, LargOutro),
              Dir is Esq + LargOutro,
              NovoX < Dir,           % Verifica sobreposição pela esquerda
              Esq < NovoX + Largura  % Verifica sobreposição pela direita
            ),
            Suportes),
    
    % Chamaria o predicado auxiliar para avaliar o polígono de sustentação
    avaliar_equilibrio(CG_X, Suportes).

% Se a lista de suportes fosse vazia, o bloco estaria flutuando livremente
% A gravidade agiria nele posteriormente, logo o movimento inicial seria válido
avaliar_equilibrio(_, []) :- !.

% 4 e 5. Calcularia os limites espaciais da base consolidada e validaria o equilíbrio
avaliar_equilibrio(CG_X, Suportes) :-
    % Extrairia a menor coordenada X entre todas as bases
    encontrar_menor_esquerda(Suportes, LimiteEsquerdoBase),
    
    % Extrairia a maior coordenada X entre todas as bases
    encontrar_maior_direita(Suportes, LimiteDireitoBase),
    
    % Validaria o equilíbrio físico conferindo a contenção do CG
    LimiteEsquerdoBase =< CG_X,
    CG_X =< LimiteDireitoBase.
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
Planos gerados manualmente para as situações apresentadas:
1.Situação 1
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
6. `move(d, pos(2, 0), pos(3, 0))`


### Questão 5
#### Planos gerados por IA (Gemini - PRO):
1. Situação 1
	1. sf1: `S = [at(a, 4, 1), at(b, 5, 1), at(c, 4, 2), at(d, 3, 0)]`
    	1. `move(d, pos(3, 1), pos(0, 1))`
		2. `move(a, pos(3, 0), pos(2, 0))`
		3. `move(b, pos(5, 0), pos(2, 1))`
		4. `move(d, pos(0, 1), pos(3, 0))`
		5. `move(b, pos(2, 1), pos(5, 1))`
		6. `move(a, pos(2, 0), pos(4, 1))`
		7. `move(c, pos(0, 0), pos(4, 2))`

     2. sf1: `S = [at(a, 4, 2), at(b, 5, 2), at(c, 4, 1), at(d, 3, 0)]`
    	1. `move(d, pos(3, 1), pos(0, 1))`
		2. `move(a, pos(3, 0), pos(2, 0))`
		3. `move(b, pos(5, 0), pos(2, 1))`
		4. `move(d, pos(0, 1), pos(3, 0))`
		5. `move(c, pos(0, 0), pos(4, 1))`
		6. `move(b, pos(2, 1), pos(5, 2))`
		7. `move(a, pos(2, 0), pos(4, 2))`
  
     3. sf1: `S = [at(a, 2, 0), at(b, 5, 0), at(c, 0, 0), at(d, 0, 1)]`
    	1. `move(d, pos(3, 1), pos(0, 1))`
     	2. `move(a, pos(3, 0), pos(2, 0))`
  
     4. sf1: `S = [at(a, 0, 1), at(b, 5, 0), at(c, 0, 0), at(d, 2, 0)]`
    	1. `move(d, pos(3, 1), pos(0, 1))`
		2. `move(a, pos(3, 0), pos(5, 1))`
		3. `move(d, pos(0, 1), pos(2, 0))`
		4. `move(a, pos(5, 1), pos(0, 1))`

2. Situação 2: `S = [at(a, 4, 2), at(b, 5, 2), at(c, 4, 1), at(d, 3, 0)]`
	1. `move(a, pos(0, 1), pos(2, 0))`
	2. `move(b, pos(1, 1), pos(2, 1))`
	3. `move(c, pos(0, 0), pos(4, 1))`
	4. `move(b, pos(2, 1), pos(5, 2))`
	5. `move(a, pos(2, 0), pos(4, 2))`

 3. Situação 3: `S = [at(a, 0, 1), at(b, 1, 1), at(c, 0, 0), at(d, 3, 0)]`
	1. `move(d, pos(3, 1), pos(0, 1))`
	2. `move(a, pos(3, 0), pos(5, 1))`
	3. `move(d, pos(0, 1), pos(2, 0))`
	4. `mmove(a, pos(5, 1), pos(0, 1))`
	5. `move(b, pos(5, 0), pos(1, 1))`
	6. `move(d, pos(2, 0), pos(3, 0))`
    

#### Planos gerado pelo planner:
1. Situação 1
    1. Sf1: (execução por tempo indefinido)
    2. Sf2: (execução por tempo indefinido)
      
    3. Sf3: `S = [at(a, 2, 0), at(b, 5, 0), at(c, 0, 0), at(d, 0, 1)]`
          1. `move(d, pos(3, 1), pos(0, 1))`
          2. `move(a, pos(3, 0), pos(2, 0))`
      
    4. Sf4: `S = [at(a, 0, 1), at(b, 5, 0), at(c, 0, 0), at(d, 2, 0)]`
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
  
#### Análise:
Considere que os planos manuais são apresentados na questão 3;
1. Situação 1
	1.1. Estado Final 1 (Sf1)
	- Manual (5 passos + 1 gravidade): Utiliza uma mecânica explícita do ambiente (apply_gravity()) para derrubar o bloco d após tirar seus suportes. É uma solução engenhosa que reduz o número de ações manuais delegando a física ao motor do jogo/simulador.
	- IA - Gemini (7 passos): A IA não levou em conta a gravidade e ela compensa criando um plano de movimentação explícito e seguro. Ela estaciona blocos em colunas intermediárias e constrói a torre passo a passo.
	- Prolog Planner (Falha): Sofreu de explosão combinatória ou loop infinito (execução por tempo indefinido).
	- Conclusão: O plano Manual é o mais eficiente operacionalmente se o ambiente suportar a função de gravidade.

	1.2. Estado Final 2 (Sf2)
	- Manual (8 passos): Alcança o objetivo, mas de forma subótima mas há movimentações redundantes de vai-e-vem (ex: move d para pos(1, 1) e logo depois para pos(3, 0)).
	- IA - Gemini (7 passos): Mais direto e eficiente que o plano manual, a IA otimizou o uso da coluna 2 como depósito temporário, evitando movimentações desnecessárias do bloco d.
	- Prolog Planner (Falha): Novamente, falhou por tempo indefinido devido à profundidade da busca necessária para reorganizar o empilhamento.
	- Conclusão: O plano da IA é o melhor, pois resolve o problema com menos passos que o humano e supera a falha de processamento do Prolog.

	1.3. Estado Final 3 (Sf3)
	- Manual (2 passos - com erro): O plano apresenta uma falha lógica de notação/humana. Ele instrui move(a, pos(2,0), pos(3,0)), mas o estado inicial de a é (3,0) e o destino desejado era (2,0), alguém inverteu a origem e o destino.
	- IA e Prolog (2 passos): Ambos geraram exatamente o mesmo plano de forma impecável e direta: movem d para revelar o espaço, e movem a para a posição correta.
	- Conclusão: Empate entre IA e Prolog. O plano manual é falho por erro de digitação/lógica invertida.

	1.4. Estado Final 4 (Sf4)
	- Manual (4 passos + gravidade): Mais uma vez, o humano utiliza a gravidade para acomodar d.
	- IA e Prolog (4 passos): Ambos geram planos idênticos e perfeito, eles alcançam o mesmo resultado com 4 passos de movimento explícito.
	- Conclusão: Empate entre IA e Prolog. Eles são superiores pois completam a tarefa no mesmo número de ações do humano.

2. Situação 2
	- Análise Geral: Os três agentes (Manual, IA e Prolog) geraram exatamente o mesmo plano de 5 passos.
	- Conclusão: Empate triplo. O problema era direto o suficiente para que a heurística humana, o cálculo probabilístico da IA e a busca em árvore do Prolog convergissem para a solução ótima absoluta.

3. Situação 3
	- Manual (6 passos): Executa um raciocínio de "quebra-cabeça deslizante", usando colunas livres para manobrar blocos e abrir caminho para d.
	- IA - Gemini (6 passos): Gerou exatamente a mesma lógica que o humano.
	- Prolog Planner (5 passos): Computacionalmente, encontrou o caminho mais curto.
	- Conclusão: O Prolog Planner vence pelo número bruto de passos (solução mais curta)







