# LifeInRussia — Game Design

## Status
Early concept / pre-production. This document should evolve before implementation becomes large.

## Core premise
The player lives an ordinary life in a fictional country. At the beginning, the player votes for a fictional political party. Each following day reflects consequences of previous public decisions and the player's own actions.

The tone gradually moves from familiar everyday life toward increasingly absurd but internally logical situations.

## Design pillars
1. **Consequences are visible** — choices must change what the player can see, hear or do in the world.
2. **Ordinary life, extraordinary rules** — large societal decisions are experienced through mundane places, people and routines.
3. **Escalating absurdity** — later days should feel stranger than earlier days without becoming random.
4. **Small world, high density** — prefer a limited set of well-developed locations that meaningfully change over time.
5. **Choices combine** — some outcomes should emerge from combinations of earlier decisions rather than one isolated branch.
6. **The player lives the day** — the game should not be only a sequence of dialogue choices or disconnected decision screens.

## Current day loop
Working concept:

`morning -> information/news -> daily objective -> exploration/interactions -> meaningful event/choice -> immediate consequences -> return/end of day -> next day`

A day should contain normal player-controlled gameplay between major scripted events.

## Structure
Current preferred direction is a hybrid structure:
- a fixed number of days / broad dramatic beats;
- variable events, world states and consequences based on prior choices;
- selected combination events triggered by multiple previous conditions.

Avoid fully exponential branching unless the scope later proves manageable.

## Player role
The player is an ordinary citizen, not a ruler or policymaker. The focus is how systemic decisions affect everyday life.

## World scope
Prefer a compact, reusable environment such as:
- apartment / apartment building;
- street or courtyard;
- shop;
- workplace;
- a few additional small locations if required.

The same spaces should visibly evolve between days.

## Visual direction
3D, pleasant and readable rather than photorealistic.
- stylized or lightly stylized realism;
- conventional rasterized rendering;
- no requirement for flagship rendering technologies;
- prioritize lighting, composition, atmosphere and coherent art direction over raw fidelity.

## Open design questions
Do not treat these as final until discussed:
- exact number of days;
- number and role of fictional parties;
- how voting/political decisions are presented during play;
- how much free exploration each day allows;
- exact player objectives between major events;
- event/state model;
- endings and replayability;
- final tone balance between satire, comedy and grounded everyday life.
