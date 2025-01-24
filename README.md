# UniversityTycoon
Part of my Masters Degree, I designed an ER Diagram for UniTycoon board game for the University of Manchester, then implemented it using SQLite and triggers.

Rules of the game:

R0: Play moves in a clockwise direction. The player rolls a 6-sided fair dice once; they move their token the number of spaces clockwise, as shown on the dice. 

R1: If a player lands on a building without an owner, they must buy it from the university (at a price that is twice the amount of the tuition fee).

R2: If player P lands on a building owned by player Q, then P pays Q the tuititon fee associated with that building. If Q owns all the buildings of a particular colour, P pays double the tuition fee.

R3: If a player is "suspended", then they are in the location "Suspension"; they must roll a 6 to get out. They immediately roll again.

R4: If a player lands on or passes "Welcome Week", they receive 100 credits.

R5: If a player rolls a 6, they move 6 squares; whatever location they land on has no effect. They then get another roll immediately.

R6: If a player lands on “You're Suspended!”, they move to the "Suspension" location, without passing Welcome Week or collecting the complimentary credits.

R7: If a player lands on a "RAG" or "Hearing" location, the action described by the card description happens.

R8: If a player lands on "Suspension" (and they are not suspended), then they are classed as "Visiting", and no action is taken (there is a visiting space for this purpose).

