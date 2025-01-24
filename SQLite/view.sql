-- View for leaderboard
-- I join player with board to then 
-- join them with Building and SpecialJunc to access the names of the locations from Building and SpecialJunc
-- I then left join a BuildingOwners
-- In BuildingOwners, I group by player name and calculcate networth by summing all buildings owned by player with their credits
-- order them by desc order (highest networth to lowest)
CREATE VIEW leaderboard AS SELECT Player.name AS name, Player.credits AS credits,
LOWER(REPLACE(COALESCE(Building.buildingName, 
                        SpecialsJunc.specialName), ' ', '_'))
                    AS location, BuildingOwners.buildings AS buildings
FROM Player
INNER JOIN Board ON Player.currentLocation = Board.tileNumber
LEFT JOIN Building ON Board.tileNumber = Building.buildingLocation
LEFT JOIN SpecialsJunc ON Board.tileNumber = SpecialsJunc.specialID
LEFT JOIN
	(SELECT Player.name, 
	LOWER(group_concat(Building.buildingName, ', ')) AS buildings,
	SUM(Building.purchaseValue) + Player.credits AS netWorth
	FROM Player
	INNER JOIN Building ON Player.id = Building.ownedBy
	GROUP BY Player.name) AS BuildingOwners ON Player.name = BuildingOwners.name
ORDER BY BuildingOwners.netWorth DESC;

