# Relatório — Atividade 2 (Jogos Digitais 2)

## 1. As duas fases

**Forest (floresta de outono)**
Tema: uma floresta de outono, com camadas de árvores ao fundo e folhas caindo na frente.

O que o jogador faz: corre para a direita por um relevo de colinas e pequenos vãos, precisa
pular os buracos sem cair, passa pela parede falsa que esconde a área secreta e sai pela zona
de fim de fase na ponta direita do mapa (tile ~70), que carrega a fase seguinte.

Decisão de desenho: a "parede falsa" foi feita como uma segunda camada de tiles (`FakeTerrain`)
usando um TileSet **sem camada de física**, em cima de um buraco de 2×2 que abri na camada de
colisão real. Fiz assim, em vez de só esconder um `Area2D` atrás do cenário, porque o bloco
falso fica visualmente idêntico ao resto do chão — a passagem não se denuncia sozinha.

**Tropic (praia tropical)**
Tema: costa tropical, céu limpo, nuvens e duas faixas de água animada ao fundo.

O que o jogador faz: essa fase é uma **subida** — em vez de andar para o lado, ele escala as
plataformas de terra de baixo para cima até o topo do mapa (a zona de fim de fase fica lá em
cima, em `y ≈ -424`), e ao alcançá-la o jogo volta para a fase inicial.

Decisão de desenho: no parallax dessa fase o eixo vertical anda pela metade do horizontal
(`motion_scale.y = motion_scale.x / 2`) e o céu fica **totalmente travado** (`0, 0`). Numa
subida longa, se o céu deslizasse junto com a câmera na mesma proporção, a sensação de
profundidade quebrava e dava um leve enjoo visual; amortecer o Y resolveu.

## 2. O parallax

**Forest** — camadas do fundo para a frente (todas com `motion_scale` X = Y):

| Camada | motion_scale | Papel |
|---|---|---|
| 6 – Distant trees | 0.1 | horizonte |
| 5 – Tree row BG 2 | 0.2 | |
| 4 – Tree row BG 1 | 0.3 | |
| 3 – Bottom leaf piles | 0.4 | |
| 2 – Trees | 0.5 | plano médio |
| 1 – Leaf top | **1.2** | primeiro plano (passa mais rápido que a câmera) |

**Tropic** — do fundo para a frente:

| Camada | motion_scale |
|---|---|
| 5 – Sky | (0, 0) |
| 4 – Floating clouds | (0.1, 0.05) |
| 3 – Background clouds | (0.2, 0.1) |
| 2 – Water v2 | (0.3, 0.15) |

Como cheguei nesses valores: a regra que segui foi "quanto mais longe, mais devagar", começando
o fundo perto de `0.1` e subindo em passos regulares até a camada onde o jogador anda (`1.0`).
Todas as camadas têm `motion_mirroring` na largura da viewport (288) para o tile repetir sem
emenda.

O que mudou da primeira tentativa para a final:
- **Primeira tentativa:** distribuí os valores de forma linear e "certinha" (0.2, 0.4, 0.6,
  0.8, 1.0). O fundo andava rápido demais e as camadas de trás pareciam grudadas umas nas
  outras — não dava para dizer o que estava longe.
- **Versão final:** comprimi as camadas distantes para bem perto de zero (0.1–0.3), abri mais
  espaço entre a camada média e o jogador, **travei o céu em 0** e adicionei uma camada de
  primeiro plano com `motion_scale > 1` (as folhas a 1.2), que passa por cima do jogador e é o
  que mais vende a profundidade. Na Tropic ainda separei X e Y porque lá o movimento é vertical.

## 3. A área secreta

- **Onde está a pista:** na fase Forest, numa quebra no desenho do chão logo antes da parede —
  a fileira de tiles decorativos e o recorte do relevo "apontam" para um trecho de parede. É uma dica visual, não um aviso escrito.
- **Onde está a entrada:** alguns tiles à frente da pista, num pedaço de parede que **parece
  sólido mas não tem colisão** (a camada `FakeTerrain`). O jogador anda para dentro dela e cai
  numa câmara escondida; lá dentro está o `Area2D` (`secret`) que dispara a troca de cena.
- **Por que separei as duas:** se a pista ficasse exatamente em cima da entrada, qualquer um
  encostando na parede já cairia dentro por acidente e o "segredo" deixaria de ser segredo.
  Separando — a dica chama a atenção num ponto, a passagem real está alguns passos adiante — o
  jogador precisa **notar, interpretar e testar**. Quem não presta atenção passa reto.

## 4. A câmera

Escolhi a câmera como **um nó separado dentro da fase, que segue o jogador por script**
(`camera.gd` procura o nó do grupo `"Player"` e copia a posição dele a cada frame). A outra
forma seria tornar a `Camera2D` **filha do jogador**.

O que eu perderia com a câmera filha do jogador:
- A configuração de câmera (principalmente os `limit_*`) viveria dentro de `player.tscn`, que é
  compartilhado por todas as fases. Hoje cada fase tem a sua instância de câmera e define os
  próprios limites (`limit_right = 834` na Tropic, `limit_top = 0` na Forest, etc.). Com a
  câmera dentro do player isso ficaria tudo igual ou cheio de gambiarra por fase.
- A câmera passaria a herdar qualquer transformação do jogador (escala, rotação, espelhamento)
  e ficaria presa a ele — não daria para, por exemplo, deixar a câmera parada numa sala ou
  apontar para outra coisa numa cutscene.

O que a forma que escolhi custa: preciso tratar o caso "jogador não encontrado"
(`push_error`), e a atualização roda todo frame no `_process`.

## 5. A transição

Quando o jogador entra na zona de fim de fase, o `Area2D` emite o sinal `body_entered`. Seria
natural chamar `get_tree().change_scene_to_file(...)` ali dentro, mas isso quebra.

O motivo: esse sinal é disparado **no meio do passo de física**, enquanto o motor ainda está
percorrendo a lista de colisões daquele frame. `change_scene_to_file` apaga a cena atual
inteira — incluindo o próprio `Area2D`, o jogador e todos os corpos físicos — no exato momento
em que o motor de física ainda está iterando sobre eles. Você está serrando o galho em que
está sentado: o motor volta da função e tenta continuar a iteração sobre objetos que não
existem mais, e o jogo trava (ou o Godot reclama de "flushing queries").

A solução é `call_deferred("load_next_scene")`: em vez de trocar a cena na hora, isso
**agenda** a troca para o fim do frame, depois que a física terminou de processar. Aí a cena
some com segurança, porque ninguém mais está mexendo naqueles nós.

## 6. O que travou

**O momento:** ao abrir a fase Forest no editor, o Godot recusava a cena com o erro:

```
Script inherits from native type 'Area2D', so it can't be assigned to an object of type: 'Node2D'
```

**O que eu achei que era:** minha primeira hipótese foi que o `level_end.tscn` (a cena
instanciada da saída de fase) tinha sido criado com o nó-raiz errado — que eu tinha feito ele
como `Node2D` e depois trocado o script para `extends Area2D`. Fui direto conferir o
`level_end.tscn`.

**O que era de verdade:** o `level_end.tscn` estava certo — raiz `Area2D`, script batendo.
O problema era na `forest.tscn`: o script `scripts/level_end.gd` (`extends Area2D`) tinha sido
colado por engano no **nó-raiz da fase**, o `Forest`, que é um `Node2D`. Provavelmente
arrastei o arquivo do script para o nó errado na árvore, ou usei "Anexar Script" com a raiz
selecionada.

**Como descobri:** relendo a mensagem de erro com calma. Ela dá os dois lados — o script quer
ser `Area2D`, mas o nó é `Node2D` — então o script existe e está num nó do tipo errado. Como
o único `Area2D` do meu projeto é a saída de fase, procurei a linha `script = ExtResource(...)`
apontando para `level_end.gd` dentro da `forest.tscn` e achei ela no bloco do nó `Forest`, não
no da instância. No Inspector o nó-raiz aparecia com um ícone de aviso no campo de script.

**As duas hipóteses não coincidiram.** Eu estava olhando para a cena errada (`level_end.tscn`)
por causa do nome no erro; a causa real estava na cena que eu tinha aberto (`forest.tscn`). A
correção foi remover o script do nó `Forest` — a instância de saída de fase já carrega o script
sozinha, pela própria cena.
