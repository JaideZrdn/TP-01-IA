% =========================================================
%  REPRESENTAÇÃO DO CONHECIMENTO
%  Mundo dos Blocos com Larguras Variáveis e Gravidade
%  Baseado no estilo STRIPS – Capítulo 17
% =========================================================
%
%  SUMÁRIO DAS SEÇÕES:
%    1. Propriedades estáticas dos blocos
%    2. Dimensões do espaço
%    3. Representação do estado
%    4. Predicados de configuração (derivados do estado)
%    5. Verificação de caminho livre (horizontal)
%       – nothing_above, destination_clear, destination_accessible
%    6. Ação: move/3 – precondição, add-list, delete-list
%    7. Gravidade – apply_gravity/2
%    8. Transição de um passo – apply_action/3
%    9. Predicados auxiliares
% =========================================================


% ---------------------------------------------------------
% 1. PROPRIEDADES ESTÁTICAS DOS BLOCOS
%
%    block_width(?Nome, ?Largura)
%    Todos os blocos têm altura 1 (implícita no domínio).
%    Essas propriedades não mudam entre estados.
% ---------------------------------------------------------

block_width(a, 1).
block_width(b, 1).
block_width(c, 2).
block_width(d, 3).


% ---------------------------------------------------------
% 2. DIMENSÕES DO ESPAÇO
%
%    grid_width(?W)  –  colunas válidas: 0 .. W-1
%    Chão em Y = 0; um bloco com Bottom = 0 está no chão.
% ---------------------------------------------------------

grid_width(6).


% ---------------------------------------------------------
% 3. REPRESENTAÇÃO DO ESTADO
%
%    Estado = lista de relacionamentos at(Bloco, Left, Bottom)
%      Bloco  = nome do bloco (a, b, c, d, ...)
%      Left   = coluna da extremidade esquerda  (inteiro >= 0)
%      Bottom = linha inferior do bloco         (0 = chão)
%
%    Um bloco de largura W com Left = L e Bottom = B
%    ocupa as células (L, B), (L+1, B), ..., (L+W-1, B).
%
%    Situação 2 – estados de exemplo (ajuste conforme a figura):
% ---------------------------------------------------------

%  S0: a e b em cima de c e d respectivamente
%
%      a(1) b(1)
%      c(2) d(3)
%      ──────────
%      0 1 2 3 4 5
%
%  a tem largura 1 (ocupa só a coluna 0, nível 1)

state_s0([ at(a, 0, 1),
           at(b, 1, 1),
           at(c, 0, 0),
           at(d, 3, 0) ]).

%  (Outros estados podem ser derivados via result/3 abaixo)


% ---------------------------------------------------------
% 4. PREDICADOS DE CONFIGURAÇÃO (derivados do estado)
% ---------------------------------------------------------

% occupies(+Block, +X, +Y, +State)
%   Bloco ocupa a célula (X, Y) no estado State.
%   Derivado de at/3 e block_width/2.

occupies(Block, X, Y, State) :-
    member(at(Block, Left, Y), State),
    block_width(Block, W),
    X >= Left,
    X < Left + W.


% cell_occupied(+X, +Y, +State)
%   Algum bloco (qualquer) ocupa a célula (X, Y).

cell_occupied(X, Y, State) :-
    occupies(_, X, Y, State).


% on_ground(+Block, +State)
%   Bloco está diretamente sobre o chão (Bottom = 0).

on_ground(Block, State) :-
    member(at(Block, _, 0), State).


% directly_supports(+Lower, +Upper, +State)
%   Lower suporta Upper:
%     – Upper está exatamente 1 nível acima de Lower (YU = YL + 1)
%     – os dois se sobrepõem horizontalmente
%
%   Condição de sobreposição horizontal entre [LL, LL+WL) e [LU, LU+WU):
%     LL < LU+WU  e  LU < LL+WL

directly_supports(Lower, Upper, State) :-
    Lower \== Upper,
    member(at(Lower, LL, YL), State),
    member(at(Upper, LU, YU), State),
    block_width(Lower, WL),
    block_width(Upper, WU),
    YU =:= YL + 1,        % adjacência vertical
    LL < LU + WU,          % sobreposição horizontal
    LU < LL + WL.


% supported(+Block, +State)
%   Bloco está suportado se:
%     (a) repousa no chão, OU
%     (b) pelo menos um bloco está diretamente abaixo dele.
%
%   Nota: basta 1 célula de sobreposição para haver suporte
%   (sem centro de gravidade explícito, conforme especificação).

supported(Block, State) :-
    on_ground(Block, State).
supported(Block, State) :-
    directly_supports(_, Block, State).


% ---------------------------------------------------------
% 5. VERIFICAÇÕES DE LIBERDADE PARA MOVIMENTO
%
%    nothing_above(+Block, +State)
%    destination_clear(+Block, +NewLeft, +NewBottom, +State)
%    destination_accessible(+Block, +NewLeft, +NewBottom, +State)
%
%    nothing_above:
%      Nenhum outro bloco ocupa o nível imediatamente acima do Block.
%      Garante o "movimento unitário" – não se pode arrastar blocos
%      que carregam outros blocos sobre si.
%      A verificação é feita apenas em Y+1 (diretamente acima);
%      se A está sobre B que está sobre C, then B já bloqueia C.
%
%    destination_clear:
%      Todas as células que Block passará a ocupar na posição destino
%      [NewLeft .. NewLeft+W-1] × {NewBottom} estão desocupadas.
%      O próprio Block é excluído da verificação (move de si mesmo).
%
%    destination_accessible:
%      O destino não está completamente cercado — ao menos UMA das três
%      direções de acesso (cima, esquerda, direita) está livre.
%      Sem isso, um bloco poderia ser "teletransportado" para dentro de
%      uma cavidade fechada por outros blocos e/ou pela borda da grade.
%
%      Exemplo de falha (estado antes da 4ª ação no cenário problemático):
%        State = [at(b,1,1), at(c,0,0), at(d,0,2)]
%        destination_accessible(a, 0, 1, State) → FALHA
%          – de cima   : d cobre (0,2)      → bloqueado
%          – da esquerda: NewLeft = 0       → parede da grade
%          – da direita : b em (1,1)        → bloqueado
% ---------------------------------------------------------

% nothing_above(+Block, +State)
%   Falha se qualquer outro bloco se sobrepõe a Block no nível Y+1.

nothing_above(Block, State) :-
    member(at(Block, Left, Bottom), State),
    block_width(Block, W),
    AboveY is Bottom + 1,
    \+ ( member(at(Other, OL, AboveY), State),
         Other \== Block,
         block_width(Other, WO),
         Left   < OL + WO,      % sobreposição horizontal
         OL     < Left + W ).


% destination_clear(+Block, +NewLeft, +NewBottom, +State)
%   Falha se qualquer outro bloco já ocupa alguma célula do destino.

destination_clear(Block, NewLeft, NewBottom, State) :-
    block_width(Block, W),
    \+ ( member(at(Other, OL, NewBottom), State),
         Other \== Block,
         block_width(Other, WO),
         NewLeft < OL + WO,     % sobreposição horizontal
         OL      < NewLeft + W ).


% destination_accessible(+Block, +NewLeft, +NewBottom, +State)
%   Verdadeiro se a posição destino NÃO está completamente cercada.
%   Um destino é considerado acessível quando PELO MENOS UMA das três
%   direções de acesso está livre:
%
%     (a) De cima   – o nível NewBottom+1 nas colunas do bloco está livre.
%         Modela o "guindaste": o bloco desce um nível a partir de cima.
%
%     (b) Da esquerda – NewLeft > 0  E  a célula (NewLeft-1, NewBottom)
%         está desocupada. Modela deslizamento pelo lado esquerdo.
%
%     (c) Da direita  – NewLeft+W < GW  E  a célula (NewLeft+W, NewBottom)
%         está desocupada. Modela deslizamento pelo lado direito.
%
%   A borda da grade é tratada como parede: se NewLeft = 0, a direção
%   esquerda é considerada bloqueada (e vice-versa para a direita).
%
%   Nota: a verificação de cima usa apenas Y = NewBottom+1 (não toda a
%   coluna acima). Em um estado estável pós-gravidade, se nada ocupa
%   NewBottom+1 nas colunas do bloco, nenhum bloco pode estar acima
%   desse nível nessas colunas (pois cairia sem suporte). Portanto,
%   verificar apenas o nível imediatamente acima é suficiente.

destination_accessible(Block, NewLeft, NewBottom, State) :-
    block_width(Block, W),
    grid_width(GW),
    AboveY is NewBottom + 1,
    RightX is NewLeft + W,
    LeftX  is NewLeft - 1,
    (
        % (a) De cima: nenhum bloco cobre [NewLeft..NewLeft+W) em AboveY
        \+ ( member(at(Other, OL, AboveY), State),
             Other \== Block,
             block_width(Other, WO),
             OL < RightX,
             NewLeft < OL + WO )
    ;
        % (b) Da esquerda: não é a borda e a célula (LeftX, NewBottom) está livre
        ( NewLeft > 0,
          \+ ( member(at(Other, OL, NewBottom), State),
               Other \== Block,
               block_width(Other, WO),
               OL =< LeftX,
               LeftX < OL + WO ) )
    ;
        % (c) Da direita: não é a borda e a célula (RightX, NewBottom) está livre
        ( RightX < GW,
          \+ ( member(at(Other, OL, NewBottom), State),
               Other \== Block,
               block_width(Other, WO),
               OL =< RightX,
               RightX < OL + WO ) )
    ).


% ---------------------------------------------------------
% 6. AÇÃO: move(Bloco, pos(OldLeft, OldBottom), pos(NewLeft, NewBottom))
%
%    Semântica:
%      • Move Bloco de (OldLeft, OldBottom) para (NewLeft, NewBottom).
%      • Permite movimento horizontal (ΔX ≠ 0), vertical (ΔY ≠ 0)
%        ou ambos simultaneamente.
%      • Blocos sobre Bloco NÃO são arrastados (nothing_above).
%      • Após a ação, apply_gravity/2 estabiliza blocos suspensos.
%        Consequência: mover para Y alto e deixar o bloco "flutuar"
%        é válido – ele cairá até encontrar suporte.
%
%    Exemplo: mover b para cima de a
%      state_s0 → b em (3,1), a em (0,1)
%      move(b, pos(3,1), pos(0,2))
%      Após gravity: b pousa em (0,2) sobre a em (0,1). ✓
%
%    Estrutura STRIPS (Capítulo 17):
%      can(Ação, Estado)      – precondição
%      adds(Ação, AddList)    – relacionamentos acrescentados
%      deletes(Ação, DelList) – relacionamentos removidos
% ---------------------------------------------------------

% can(+Action, +State)
%   Verdadeiro se a ação pode ser executada no estado State.
%
%   Precondições:
%     1. Bloco existe no domínio (block_width/2 definido).
%     2. Bloco está na posição declarada.
%     3. Há deslocamento efetivo (posição muda em X ou Y).
%     4. Nenhum outro bloco está diretamente sobre o bloco (nothing_above).
%     5. Nova posição cabe dentro da grid (X e Y válidos).
%     6. Células do destino estão livres (destination_clear).
%     7. Destino não está completamente cercado (destination_accessible).

can(move(Block, pos(OldLeft, OldBottom), pos(NewLeft, NewBottom)), State) :-
    block_width(Block, W),                                   % 1. bloco no domínio
    member(at(Block, OldLeft, OldBottom), State),            % 2. posição correta
    ( NewLeft \== OldLeft ; NewBottom \== OldBottom ),       % 3. deslocamento efetivo
    nothing_above(Block, State),                             % 4. nada sobre o bloco
    grid_width(GW),
    NewLeft   >= 0,                                          % 5a. dentro da grid (esq.)
    NewLeft + W =< GW,                                       % 5b. dentro da grid (dir.)
    NewBottom >= 0,                                          % 5c. acima do chão
    destination_clear(Block, NewLeft, NewBottom, State),     % 6. destino livre
    destination_accessible(Block, NewLeft, NewBottom, State).% 7. destino acessível


% adds(+Action, -AddList)
%   Relacionamentos acrescentados ao estado pela ação.

adds(move(Block, pos(_OldLeft, _OldBottom), pos(NewLeft, NewBottom)),
     [at(Block, NewLeft, NewBottom)]).


% deletes(+Action, -DelList)
%   Relacionamentos removidos do estado pela ação.

deletes(move(Block, pos(OldLeft, OldBottom), pos(_NewLeft, _NewBottom)),
        [at(Block, OldLeft, OldBottom)]).

% preconditions(+Action, -PreCondList)
%   Retorna a lista de fatos lógicos estruturais necessários antes da ação.
%   Condições complexas (como espaço livre) são avaliadas no forward pass.

preconditions(move(Block, pos(OldLeft, OldBottom), pos(_NewLeft, _NewBottom)),
              [at(Block, OldLeft, OldBottom)]).

% ---------------------------------------------------------
% 7. GRAVIDADE
%
%    apply_gravity(+State, -FinalState)
%
%    Algoritmo:
%      a) Identifica TODOS os blocos sem suporte no estado atual.
%      b) Desce cada um deles 1 nível simultaneamente.
%      c) Repete até que nenhum bloco esteja suspenso (estado estável).
%
%    Blocos que perdem suporte após uma movimentação (porque o bloco
%    que os sustentava saiu de baixo) caem aqui.
% ---------------------------------------------------------

apply_gravity(State, FinalState) :-
    findall(at(B, L, Y),
            ( member(at(B, L, Y), State),
              Y > 0,
              \+ supported(B, State) ),
            Floating),
    Floating \= [],                         % há blocos suspensos
    !,
    drop_all(Floating, State, State1),      % desce 1 nível cada bloco
    apply_gravity(State1, FinalState).      % verifica novamente

apply_gravity(State, State).               % estado já estável


% drop_all(+FloatingList, +State0, -State1)
%   Desce cada bloco da lista 1 nível (Y → Y-1) no estado.
%   Os blocos são processados sequencialmente; como nenhum bloco
%   suspenso suporta outro bloco suspenso (se o fizesse, o de cima
%   não estaria na lista), a ordem não afeta o resultado.

drop_all([], State, State).
drop_all([at(Block, Left, Bottom) | Rest], State0, FinalState) :-
    NewBottom is Bottom - 1,
    select(at(Block, Left, Bottom), State0, Temp),
    drop_all(Rest, [at(Block, Left, NewBottom) | Temp], FinalState).


% ---------------------------------------------------------
% 8. TRANSIÇÃO DE UM PASSO
%
%    apply_action(+Action, +State, -FinalState)
%
%    Aplica UMA ação ao estado e estabiliza com gravidade.
%    Bloco de construção para o planejador (blocos_planejador.pl).
% ---------------------------------------------------------

apply_action(Action, State, FinalState) :-
    can(Action, State),
    Action = move(Block, pos(OL, OB), pos(NL, NB)),
    format('Executando: Mover bloco [~w] de (~d,~d) para (~d,~d)~n', 
           [Block, OL, OB, NL, NB]),
    deletes(Action, DelList),
    delete_all(State, DelList, State1),
    adds(Action, AddList),
    append(AddList, State1, MidState),
    apply_gravity(MidState, FinalState).


% ---------------------------------------------------------
% 9. PREDICADOS AUXILIARES
% ---------------------------------------------------------

% delete_all(+State, +ToRemove, -Result)
%   Remove todos os elementos de ToRemove do State.
%   Ignora silenciosamente elementos não encontrados.

delete_all(State, [], State).
delete_all(State0, [H | T], Result) :-
    ( select(H, State0, State1) -> true ; State1 = State0 ),
    delete_all(State1, T, Result).


% =========================================================
%  EXEMPLOS DE USO – domínio isolado
%
%  ?- state_s0(S), can(move(a, pos(0,1), pos(1,1)), S).
%  ?- state_s0(S), apply_action(move(a, pos(0,1), pos(2,1)), S, S1).
%  ?- state_s0(S), directly_supports(c, a, S).
%  ?- state_s0(S), nothing_above(a, S).
%  ?- state_s0(S), apply_gravity(S, S).   % S0 já estável
%
%  Para planejamento, carregue também blocos_planejador.pl
% =========================================================

% =========================================================
%  PLANEJADOR – Mundo dos Blocos com Larguras Variáveis
%  Estratégia: Goal Regression + Partial Order Planning (POP)
%  Baseado nos Capítulos 17 e 18 de Bratko (Prolog for AI)
% =========================================================
%
%  Pré-requisito: ida_blocos_dominio.pl deve estar carregado.
%
%  PREDICADO PRINCIPAL:
%
%    result(?Plan, +InitState, ?FinalState)
%
%    Modo execução   (Plan instanciado):
%      result(+Plan, +State, -FinalState)
%      Aplica a sequência de ações e retorna o estado final.
%
%    Modo planejamento (Plan não instanciado):
%      result(-Plan, +InitState, +GoalFacts)
%      Encontra a sequência MÍNIMA de ações que leva
%      InitState a um estado que satisfaz GoalFacts.
%      Usa Goal Regression com aprofundamento iterativo,
%      com verificação forward (POP) para validar o plano.
%
%  CONSULTAS DE EXEMPLO:
%    ?- state_s0(S),
%       result(Plan, S, [at(a, 4, 2), at(b, 2, 0),
%                        at(c, 4, 1), at(d, 3, 0)]).
%
%    ?- state_s1(S),
%       result(Plan, S, [at(a, 4, 2), at(b, 2, 0),
%                        at(c, 4, 1), at(d, 3, 0)]).
%
%  SUMÁRIO DAS SEÇÕES:
%    1. Predicado principal result/3
%    2. Aplicação de plano apply_plan/3
%    3. Verificação de objetivo state_includes/2
%    4. Goal Regression: regress/3, preserves/2
%    5. Planejador POP com regressão e aprofundamento iterativo
%    6. Geração de ações candidatas candidate_action/2
%    7. Estado alternativo state_s1/1
%    8. Predicados auxiliares de conjuntos
% =========================================================

% :- consult('ida_blocos_dominio.pl').


% ---------------------------------------------------------
% 7. ESTADO ALTERNATIVO
%
%  state_s1: configuração onde b está em (1,1)
%  Útil para o exemplo da saída esperada:
%
%      a(1)
%      b(1)
%      c(2) d(3)
%      ──────────────
%      0 1 2 3 4 5
%
%  a em (0,2), b em (1,1), c em (0,0), d em (3,0)
%  Nota: b suporta a (YA=2=YB+1=2, overlap: 0<2 e 1<1 → fail)
%  Ajuste: a em (1,2) sobre b em (1,1) ✓ (LL=1=LU=1, overlap: 1<2 e 1<2)
% ---------------------------------------------------------

state_s1([ at(a, 1, 2),
           at(b, 1, 1),
           at(c, 0, 0),
           at(d, 3, 0) ]).


% ---------------------------------------------------------
% 1. PREDICADO PRINCIPAL: result/3
%
%    Despacha entre modo execução (Plan instanciado) e
%    modo planejamento (Plan não instanciado).
% ---------------------------------------------------------

result(Plan, InitState, FinalState) :-
    ( nonvar(Plan)
    -> apply_plan(Plan, InitState, FinalState)
    ;  pop_solve(InitState, FinalState, Plan, _FinalSt)
    ).


% ---------------------------------------------------------
% 2. APLICAÇÃO DE PLANO (modo execução)
%
%    apply_plan(+Plan, +State, -FinalState)
%    Aplica cada ação sequencialmente usando apply_action/3
%    do domínio (que inclui can/2 + STRIPS + gravidade).
% ---------------------------------------------------------

apply_plan([], State, State).
apply_plan([Action | Rest], State0, FinalState) :-
    apply_action(Action, State0, State1),
    apply_plan(Rest, State1, FinalState).


% ---------------------------------------------------------
% 3. VERIFICAÇÃO DE OBJETIVO
%
%    state_includes(+State, +GoalFacts)
%    Verdadeiro se todo fato de GoalFacts está em State.
% ---------------------------------------------------------

state_includes(State, GoalFacts) :-
    \+ ( member(Fact, GoalFacts),
         \+ member(Fact, State) ).


% ---------------------------------------------------------
% 4. GOAL REGRESSION (Capítulo 17, Seção 17.3)
%
%    regress(+Goals, +Action, -RegressedGoals)
%
%    Regride Goals através de Action. Produz RegressedGoals:
%    o conjunto de condições que devem ser verdadeiras ANTES
%    de Action para que Goals sejam verdadeiras DEPOIS.
%
%    Algoritmo (Fig. 17.5 de Bratko):
%      RegressedGoals = can(Action)              % precondições
%                     ∪ (Goals − adds(Action))   % objetivos não dados pela ação
%
%    Restrição (preservação): se Action destrói algum Goal
%    (Goals ∩ deletes(Action) ≠ ∅), a regressão é impossível → fail.
%
%    preserves(+Action, +Goals)
%    Verdadeiro se Action não destrói nenhum objetivo em Goals.
% ---------------------------------------------------------

preserves(Action, Goals) :-
    deletes(Action, DelList),
    \+ ( member(G, Goals), member(G, DelList) ).

regress(Goals, Action, RegressedGoals) :-
    preserves(Action, Goals),
    adds(Action, AddList),
    preconditions(Action, PreCond), % <-- Trocado de can/2 para preconditions/2
    subtract_list(Goals, AddList, RemainingGoals),
    union_list(PreCond, RemainingGoals, RegressedGoals).


% ---------------------------------------------------------
% 5. PLANEJADOR POP COM REGRESSÃO
%    (Capítulo 17.3 + 17.6 + Capítulo 18.1–18.2)
%
%    pop_solve(+InitState, +GoalFacts, -Plan, -FinalState)
%
%    Estratégia híbrida backward/forward:
%
%    FASE BACKWARD (Goal Regression):
%      – Parte dos GoalFacts e regride através de ações candidatas.
%      – Em cada passo, seleciona um objetivo aberto (não satisfeito
%        no InitState) e encontra uma ação que o atinge (relevante).
%      – Regride TODOS os objetivos correntes através dessa ação,
%        obtendo os novos objetivos a satisfazer antes dela.
%      – Repete até que todos os objetivos sejam satisfeitos pelo
%        InitState (plano completo na direção backward).
%      – Aprofundamento iterativo (between/3) limita o número de ações.
%
%    FASE FORWARD (verificação POP):
%      – O plano construído é invertido e executado a partir de InitState.
%      – Se o estado final satisfaz GoalFacts originais → plano válido.
%      – Caso contrário → backtrack e tenta outra sequência de regressão.
%
%    Controle de ciclos:
%      – Visited acumula conjuntos de objetivos normalizados (msort)
%        já explorados, evitando loops de regressão.
%
%    Ordenação parcial (POP):
%      – A regressão produz naturalmente um plano parcialmente ordenado:
%        ações cuja ordem não importa podem aparecer em qualquer sequência.
%      – A verificação forward valida apenas UMA linearização; outras
%        linearizações válidas existem quando as ações são independentes.
% ---------------------------------------------------------

pop_solve(InitState, GoalFacts, Plan, FinalState) :-
    msort(GoalFacts, NormGoals),
    between(0, 20, MaxLen),
    pop_regress(NormGoals, InitState, MaxLen, PlanRev, [NormGoals]),
    reverse(PlanRev, Plan),
    apply_plan(Plan, InitState, FinalState),
    state_includes(FinalState, GoalFacts),
    !.


% pop_regress(+Goals, +InitState, +MaxLen, -PlanRev, +Visited)
%
%   Caso base: todos os objetivos satisfeitos no InitState.

pop_regress(Goals, InitState, _, [], _) :-
    state_includes(InitState, Goals),
    !.

% Caso recursivo: seleciona objetivo aberto, encontra ação candidata,
% regride, verifica ciclo, recursa.

pop_regress(Goals, InitState, MaxLen, [Action | RestPlanRev], Visited) :-
    MaxLen > 0,
    % Seleciona objetivo não satisfeito no InitState
    select_open_goal(Goals, InitState, Goal),
    % Ação candidata relevante para Goal (adiciona Goal)
    candidate_action(Goal, Action),
    % Regride todos os objetivos correntes: preserva + substitui
    regress(Goals, Action, RegressedGoals),
    % Normaliza e verifica ausência de ciclo
    msort(RegressedGoals, NormReg),
    \+ member(NormReg, Visited),
    MaxLen1 is MaxLen - 1,
    pop_regress(NormReg, InitState, MaxLen1, RestPlanRev,
                [NormReg | Visited]).


% select_open_goal(+Goals, +InitState, -Goal)
%   Seleciona o primeiro objetivo em Goals não satisfeito em InitState.
%
%   Heurística de seleção (Capítulo 17.4):
%     Objetivos mais difíceis de atingir deveriam ser selecionados
%     primeiro. Aqui usamos a ordem natural da lista; pode ser
%     refinado priorizando objetivos cujos blocos estão mais longe
%     do destino ou têm mais blocos acima deles.

select_open_goal(Goals, InitState, Goal) :-
    member(Goal, Goals),
    \+ member(Goal, InitState).


% ---------------------------------------------------------
% 6. GERAÇÃO DE AÇÕES CANDIDATAS
%
%    candidate_action(+Goal, -Action)
%
%    Goal = at(Block, NL, NB)  →  action = move(Block, pos(OL,OB), pos(NL,NB))
%
%    A posição de origem (OL, OB) é enumerada por between/3
%    dentro dos limites do domínio. A viabilidade completa
%    (can/2, nothing_above, destination_clear) é verificada:
%      – em regress/3: can(Action, PreCond) deve ser satisfeito
%        com as precondições corretas, mas sem estado concreto
%        disponível durante a regressão pura.
%      – em apply_plan: apply_action/3 chama can/2 com o estado
%        real, garantindo correção na execução forward.
%
%    Nota sobre can/2 durante regressão:
%      can/2 em ida_blocos_dominio.pl requer o estado State
%      (member(at(Block,OL,OB), State), nothing_above, etc.).
%      Durante a regressão pura não temos um estado concreto,
%      então candidate_action/2 apenas exige block_width/2
%      para confirmar que o bloco existe no domínio e que as
%      coordenadas são geometricamente válidas.
%      A verificação completa ocorre no forward pass.
% ---------------------------------------------------------

candidate_action(at(Block, NewLeft, NewBottom),
                 move(Block, pos(OldLeft, OldBottom),
                             pos(NewLeft, NewBottom))) :-
    block_width(Block, W),
    grid_width(GW),
    max_height_val(MaxH),
    % Garantia geométrica: nova posição cabe na grid
    NewLeft >= 0,
    NewLeft + W =< GW,
    NewBottom >= 0,
    % Origem enumerada dentro dos limites
    MaxOldLeft is GW - W,
    between(0, MaxOldLeft, OldLeft),
    between(0, MaxH, OldBottom),
    % Deslocamento efetivo
    \+ (OldLeft =:= NewLeft, OldBottom =:= NewBottom).


% max_height_val(-H)
%   Altura máxima de empilhamento = número de blocos no domínio.

max_height_val(H) :-
    findall(_, block_width(_, _), Bs),
    length(Bs, H).


% ---------------------------------------------------------
% 8. PREDICADOS AUXILIARES DE CONJUNTOS
%
%    subtract_list(+L1, +L2, -Diff)
%    Diff = L1 − L2  (remove de L1 todo elemento presente em L2)
%
%    union_list(+L1, +L2, -Union)
%    Union = L1 ∪ L2  (sem duplicatas, preserva ordem de L1 primeiro)
% ---------------------------------------------------------

subtract_list([], _, []).
subtract_list([H|T], L2, Diff) :-
    ( member(H, L2)
    -> subtract_list(T, L2, Diff)
    ;  Diff = [H | Rest],
       subtract_list(T, L2, Rest)
    ).

union_list([], L, L).
union_list([H|T], L2, Union) :-
    ( member(H, L2)
    -> union_list(T, L2, Union)
    ;  Union = [H | Rest],
       union_list(T, L2, Rest)
    ).


% =========================================================
%  EXEMPLOS DE USO COMPLETOS
%
%  % ── planejamento com state_s0 ─────────────────────────
%  %  state_s0: [at(a,0,1), at(b,3,1), at(c,0,0), at(d,3,0)]
%  ?- state_s0(S), result(Plan, S,
%       [at(a,4,2), at(b,2,0), at(c,4,1), at(d,3,0)]).
%
%  % ── planejamento com state_s1 ─────────────────────────
%  %  state_s1: [at(a,1,2), at(b,1,1), at(c,0,0), at(d,3,0)]
%  ?- state_s1(S), result(Plan, S,
%       [at(a,4,2), at(b,2,0), at(c,4,1), at(d,3,0)]).
%
%  % ── execução de plano dado ────────────────────────────
%  ?- state_s0(S),
%     result([move(b, pos(3,1), pos(2,0)),
%             move(a, pos(0,1), pos(4,2))], S, S1).
%
%  % ── objetivo parcial (subconjunto de objetivos) ───────
%  ?- state_s0(S),
%     result(Plan, S, [at(b, 2, 0), at(c, 4, 1)]).
%
%  % ── regressão isolada ─────────────────────────────────
%  %  Regride [at(a,4,2), at(c,4,1)] através de move(c,...)
%  ?- regress([at(a,4,2), at(c,4,1)],
%             move(c, pos(0,0), pos(4,1)),
%             Reg).
%
%  % ── verificação de preservação ────────────────────────
%  ?- preserves(move(b, pos(3,1), pos(2,0)), [at(a,0,1), at(c,0,0)]).
%  %  true – mover b não destrói at(a,...) nem at(c,...)
%
%  % ── state_includes ────────────────────────────────────
%  ?- state_includes([at(a,4,2), at(b,2,0), at(c,4,1), at(d,3,0)],
%                    [at(b,2,0), at(d,3,0)]).
%  %  true
% =========================================================
