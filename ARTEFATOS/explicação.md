# Planejador Mundo dos Blocos com Larguras Variáveis

Esta documentação descreve a implementação de um sistema de planejamento em Prolog para o **Mundo dos Blocos**, onde os blocos possuem larguras distintas, o espaço é limitado por um grid e a física é regida por uma regra simplificada de gravidade.

---

## 1. Representação do Conhecimento

### Propriedades Estáticas

Cada bloco possui uma largura fixa que não se altera durante a execução. A altura de todos os blocos é implicitamente **1**.

- `block_width(Nome, Largura).`
    
- **Exemplos:** Blocos `a` e `b` possuem largura 1; `c` tem largura 2; `d` tem largura 3.
    

### Estado do Mundo

O estado é representado por uma lista de predicados `at(Bloco, Left, Bottom)`, onde:

- `Left`: Coluna da extremidade esquerda.
    
- `Bottom`: Nível vertical (0 é o chão).
    
- **Dimensões:** O grid possui uma largura máxima definida por `grid_width(6)`.
    

---

## 2. Predicados de Configuração e Física

A solução utiliza predicados derivados para entender a geometria do estado atual:

### Ocupação e Suporte

- **`occupies(Block, X, Y, State)`**: Determina se uma célula específica $(X, Y)$ está ocupada por um bloco, considerando sua largura.
    
- **`directly_supports(Lower, Upper, State)`**: Verifica se o bloco `Lower` está imediatamente abaixo de `Upper` e se há sobreposição horizontal entre eles.
    
- **`supported(Block, State)`**: Um bloco é considerado estável se estiver no chão ou se houver **pelo menos um bloco** (independente do centro de gravidade) fornecendo suporte direto abaixo dele.
    

### Regras de Movimento (Restrições)

- **Movimento Unitário (`nothing_above`)**: Apenas um bloco pode ser movido por vez, mesmo se arrastado, os blocos acima não são carregados junto.
    
- **Espaço Livre (`destination_clear`)**: Garante que todas as células que o bloco ocupará na posição de destino estejam vazias.
    

---

## 3. Ações e Transições

### Ação `move/3`

A ação principal é `move(Block, pos(OldL, OldB), pos(NewL, NewB))`. Ela segue a estrutura **STRIPS**:

- **Precondições (`can`)**: O bloco deve existir, estar na posição correta, o destino deve estar dentro do grid, o destino deve estar livre e não pode haver nada sobre o bloco.
    
- **Efeitos (`adds` / `deletes`)**: Remove a posição antiga e adiciona a nova coordenada ao estado.
    

### Gravidade (`apply_gravity`)

Diferente do mundo dos blocos clássico, este domínio permite mover um bloco para uma posição "flutuante". O sistema então aplica a gravidade de forma iterativa:

1. Identifica todos os blocos sem suporte.
    
2. Desce cada bloco suspenso em 1 nível simultaneamente.
    
3. Repete o processo até que o estado seja estável.
    

---

## 4. Estratégia de Planejamento

O planejador utiliza uma abordagem híbrida de **Regressão de Objetivos (Goal Regression)** e **Ordenação Parcial (POP)**:

### Fase Backward (Regressão)

- Parte do objetivo final (`GoalFacts`) e trabalha de trás para frente.
    
- **`regress(Goals, Action, RegressedGoals)`**: Calcula quais condições precisariam ser verdadeiras antes de uma ação para que o objetivo seja alcançado, garantindo que a ação não destrua outros objetivos já satisfeitos (`preserves`).
    
- Utiliza **Aprofundamento Iterativo** (`between(0, 20, MaxLen)`) para encontrar o plano com o menor número de passos.
    

### Fase Forward (Verificação)

- Como a regressão é feita sem um estado concreto, o plano gerado é invertido e testado a partir do estado inicial (`InitState`) usando `apply_plan`.
    
- Cada passo valida as precondições físicas e aplica a gravidade para garantir que o estado resultante de cada movimento é válido conforme as regras do domínio.
    

---

## 5. Exemplos de Uso

Para encontrar um plano que mova blocos para posições específicas:

Prolog

```
?- 
	Initial = [at(a,0,1), at(b,1,1), at(c,0,0), at(d,3,0)],
	Goal = [at(a, 4, 2), at(b, 2, 0), at(c, 4, 1), at(d, 3, 0)],
	result(Plan, Initial, Goal).
```

_O sistema retornará a lista de movimentos `Plan` que transforma o estado `S` no objetivo desejado._
