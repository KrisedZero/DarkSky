This file lists numeric values and probabilities for game mechanics. All numbers are tunable via constants.

Aspect	Parameter	Value / Range
Player	Move Speed	120 pixels/sec (base)
	Run Speed	180 px/sec (sprint)
	Max Health/Energy	100
	Lantern Oil (start)	600 sec (10 min)
	Energy Cost (walking)	0.1% per second
	Energy Cost (running)	0.25% per second
	Crouch Speed	80 px/sec (when hiding)
Monster	Patrol Speed	90 px/sec
	Chase Speed	140 px/sec
	Detection Radius	8 tiles (sharp ears)
	Chase Radius	12 tiles (pursue range)
	Vision Angle	110° cone
	Hearing Range	4 tiles (footsteps)
	Roam Pause Time	1–3 sec (random)
Items	Apple (food)	+20 energy
	Cookie (food)	+10 energy
	Cheese (food)	+25 energy
	Pie (food)	+35 energy
	Small Oil (bottle)	+60 sec lantern
	Large Oil (tank)	+120 sec lantern
	Night Vision (potion)	120 sec effect
	Danger Sense (amulet)	Permanent (once acquired)
	Invisible Cloak	1 hit (one usage)
	Sleep Potion	Skip to morning (weakens monsters by ~15%)
	Blood Codex	Toggles Blood Mode (permanent)
Coins	1 coin	Very Common (20%)
	2-3 coins	Very Common (15% each)
	4-7 coins	Common (10% each)
	8 coins	Rare (5%)
	9 coins	Very Rare (2%)
	10 coins	Ultra Rare (0.5%)

    
Notes:

Health/Energy regen is minimal (1% per minute) unless sleeping.
Player pick up sound cues exist for coins and items.
All probabilities are per chest or per spawn attempt.
Tuning strategy: Start with above values; use playtesting to adjust (avoid having empty levels of oil or too many monsters).