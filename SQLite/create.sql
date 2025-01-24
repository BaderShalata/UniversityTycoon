-- TOKENS
CREATE TABLE Tokens (
    name VARCHAR(30) NOT NULL PRIMARY KEY,
    isAvailable INT NOT NULL DEFAULT 1
);
-- BOARD
CREATE TABLE Board (
    tileNumber INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    tileType VARCHAR(30) NOT NULL
);
-- SPECIALS
CREATE TABLE SpecialsDesc (
    specialName VARCHAR(30) NOT NULL PRIMARY KEY,
    specialDescription VARCHAR(60) NOT NULL
);
CREATE TABLE SpecialsJunc (
    specialID INT NOT NULL PRIMARY KEY,
    specialName VARCHAR(60) NOT NULL,
    FOREIGN KEY (specialID) REFERENCES board(tileNumber),
    FOREIGN KEY (specialName) REFERENCES specialsDesc(specialName)
);

-- PLAYER
CREATE TABLE Player (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(30) NOT NULL,
    credits INT NOT NULL,
    chosenToken VARCHAR(30) NOT NULL,
    currentLocation INT NOT NULL DEFAULT 0,
    currentPlayerStatus VARCHAR(30) NOT NULL DEFAULT 'active',
    isUsingSpecial INT NOT NULL DEFAULT 0,
    oldLocation VARCHAR(30),
    FOREIGN KEY (currentLocation) REFERENCES board(tileNumber),
    FOREIGN KEY (chosenToken) REFERENCES tokens(name)
);
-- BUILDING
CREATE TABLE Building (
    buildingName VARCHAR(30) NOT NULL PRIMARY KEY,
    buildingLocation INT NOT NULL,
   tuitionfee INT NOT NULL,
    ownedby INT,
    purchaseValue INT NOT NULL,
    color VARCHAR(30) NOT NULL,
    FOREIGN KEY(buildingLocation) REFERENCES board(tileNumber),
    FOREIGN KEY(ownedBy) REFERENCES player(id)
);
-- AUDIT
CREATE TABLE Audit (
    auditID INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    playerid INT NOT NULL,
    playerLocation INT,
    currentCredits INT,
    roundNumber INT NOT NULL,
    rolledNumber INT NOT NULL CHECK(rolledNumber > 0 AND rolledNumber <=6),
    FOREIGN KEY(playerid) REFERENCES player(id)
);
-- TRIGGERS
CREATE TRIGGER locationUpdate
BEFORE INSERT ON Audit
FOR EACH ROW
BEGIN 
    UPDATE Player
    SET oldLocation = currentLocation,
        currentLocation = 
        CASE 
            -- Moving to tile 7 when landing on tile 17
            WHEN NEW.rolledNumber != 6 AND (Player.currentLocation + NEW.rolledNumber) = 17
            THEN 7
            -- Entering a new cycle if exceeding max tile number
            WHEN NEW.rolledNumber != 6 AND (Player.currentLocation + NEW.rolledNumber) > (SELECT MAX(tileNumber) FROM Board)
            THEN (Player.currentLocation + NEW.rolledNumber) % (SELECT MAX(tileNumber) + 1 FROM Board)
            -- Regular move without entering a new cycle or landing on specific tiles
            ELSE Player.currentLocation + NEW.rolledNumber
        END
    WHERE Player.id = NEW.playerid;
END;

CREATE TRIGGER auditLocationUpdate
AFTER INSERT ON Audit
FOR EACH ROW
BEGIN 
UPDATE Audit
 SET playerLocation = (SELECT currentLocation FROM Player WHERE id = NEW.playerid)
 WHERE Audit.auditID = NEW.auditID AND Audit.roundNumber = NEW.roundNumber;
END;

CREATE TRIGGER creditsUpdate
AFTER INSERT ON Audit
FOR EACH ROW
WHEN NEW.rolledNumber != 6
BEGIN
    -- Update Player credits for the player who just moved
    UPDATE Player
    SET credits =
        CASE
            -- WHEN PLAYER LANDS ON WELCOME WEEK
            WHEN (SELECT currentLocation FROM Player WHERE id = NEW.playerid) = 0
            THEN credits + 100
            -- IF PLAYER ENTER A NEW CYCLE BUT LANDED ON OWNED BUILDING
            WHEN
                (SELECT currentLocation FROM Player WHERE id = NEW.playerid) < (SELECT oldLocation FROM Player WHERE id = NEW.playerid)
                AND (SELECT currentPlayerStatus FROM Player WHERE id = NEW.playerid) != 'suspended'
                AND 
                (SELECT ownedBy 
                FROM Building 
                WHERE buildingLocation = 
                (SELECT currentLocation FROM Player WHERE id = NEW.playerid)) IS NOT NULL
                AND 
                (SELECT ownedBy
                FROM Building 
                WHERE buildingLocation = 
                (SELECT currentLocation FROM Player WHERE id = NEW.playerid)) != NEW.playerid
            THEN credits + 100 - (SELECT tuitionfee 
                                FROM Building
                                WHERE buildingLocation =
                                (SELECT currentLocation
                                FROM Player 
                                WHERE id = NEW.playerid))
            
            -- IF PLAYER ENTER A NEW CYCLE BUT LANDED ON UNOWNED BUILDING
            WHEN (SELECT currentLocation 
                 FROM Player 
                 WHERE id = NEW.playerid) < (SELECT oldLocation 
                                            FROM Player 
                                            WHERE id = NEW.playerid)
                AND (SELECT currentPlayerStatus 
                    FROM Player 
                    WHERE id = NEW.playerid) != 'suspended'
                AND 
                (SELECT ownedBy 
                FROM Building 
                WHERE buildingLocation = 
                (SELECT currentLocation FROM Player WHERE id = NEW.playerid)) IS NULL
                AND 
                (SELECT ownedBy
                FROM Building 
                WHERE buildingLocation = 
                (SELECT currentLocation 
                FROM Player 
                WHERE id = NEW.playerid)) != NEW.playerid
            THEN credits + 100 - (SELECT purchaseValue 
                                 FROM Building 
                                 WHERE buildingLocation = 
                                 (SELECT currentLocation 
                                 FROM Player
                                 WHERE id = NEW.playerid))

            -- IF PLAYER ENTER A NEW CYCLE BUT LANDED ON HIS OWN
            WHEN (SELECT currentLocation 
                 FROM Player 
                 WHERE id = NEW.playerid) < (SELECT oldLocation 
                                            FROM Player 
                                            WHERE id = NEW.playerid)
                AND (SELECT currentPlayerStatus FROM Player WHERE id = NEW.playerid) != 'suspended'
                AND
                (SELECT ownedBy 
                FROM Building 
                WHERE buildingLocation = 
                (SELECT currentLocation 
                FROM Player 
                WHERE id = NEW.playerid)) IS NOT NULL
                AND
                (SELECT ownedBy 
                FROM Building 
                WHERE buildingLocation = 
                (SELECT currentLocation 
                FROM Player 
                WHERE id = NEW.playerid)) = NEW.playerid
            THEN credits + 100

            -- TUITION FEE IF BUILDING IS OWNED BY SOMEONE ELSE
            WHEN 
                (SELECT ownedBy 
                FROM Building 
                WHERE Building.buildingLocation = 
                (SELECT currentLocation 
                FROM Player 
                WHERE id = NEW.playerid)) IS NOT NULL
                AND 
                (SELECT ownedBy 
                FROM Building 
                WHERE Building.buildingLocation = 
                (SELECT currentLocation 
                FROM Player 
                WHERE id = NEW.playerid)) != NEW.playerid
            THEN credits - (SELECT tuitionfee
                           FROM Building 
                           WHERE Building.buildingLocation = 
                           (SELECT currentLocation 
                           FROM Player 
                           WHERE id = NEW.playerid))
            
            -- IF PLAYER LANDS ON HIS OWN BUILDING
            WHEN 
                (SELECT ownedBy 
                FROM Building 
                WHERE Building.buildingLocation = 
                (SELECT currentLocation 
                FROM Player 
                WHERE id = NEW.playerid)) IS NOT NULL
                AND 
                (SELECT ownedBy
                FROM Building 
                WHERE Building.buildingLocation = 
                (SELECT currentLocation 
                FROM Player 
                WHERE id = NEW.playerid)) = NEW.playerid
            THEN credits

            -- Handling Hearing penalties
            WHEN (SELECT currentLocation FROM Player WHERE id = NEW.playerid) =
                (SELECT board.tileNumber
                FROM board INNER JOIN specialsJunc ON board.tileNumber = specialsJunc.specialID
                WHERE specialName = 'Hearing_1')
            THEN credits - 20

            WHEN (SELECT currentLocation FROM Player WHERE id = NEW.playerid) =
                (SELECT board.tileNumber
                FROM board INNER JOIN specialsJunc ON board.tileNumber = specialsJunc.specialID
                WHERE specialName = 'Hearing_2')
            THEN credits - 25

            -- RAGS rewards
            WHEN  (SELECT currentLocation FROM Player WHERE id = NEW.playerid) =
                (SELECT board.tileNumber
                FROM board INNER JOIN specialsJunc ON board.tileNumber = specialsJunc.specialID 
                WHERE specialName = 'RAG_1')
            THEN credits + 15

            WHEN (SELECT currentLocation FROM Player WHERE id = NEW.playerid) =
                (SELECT board.tileNumber
                FROM board INNER JOIN specialsJunc ON board.tileNumber = specialsJunc.specialID 
                WHERE specialName = 'RAG_2')
            THEN credits - (SELECT COUNT(*) - 1 FROM Player) * 10

            -- If none of the conditions are met, retain current credits
            ELSE credits
        END
    WHERE id = NEW.playerid;
    
    -- Add tuition fee to owner
    UPDATE Player
    SET credits = credits +
        (SELECT tuitionfee FROM Building WHERE buildingLocation =
        (SELECT currentLocation FROM Player WHERE id = NEW.playerid))
    WHERE id =
        (SELECT ownedBy FROM Building WHERE buildingLocation =
        (SELECT currentLocation FROM Player WHERE id = NEW.playerid))
    AND (SELECT ownedBy FROM Building WHERE buildingLocation =
        (SELECT currentLocation FROM Player WHERE id = NEW.playerid)) != NEW.playerid
    AND (SELECT ownedBy FROM Building WHERE buildingLocation =
        (SELECT currentLocation FROM Player WHERE id = NEW.playerid)) IS NOT NULL
        AND NEW.rolledNumber != 6;
    
    -- Add 10 credits to every other player
    UPDATE Player
    SET credits = credits + 10
    WHERE id != NEW.playerid AND (SELECT currentLocation FROM Player WHERE id = NEW.playerid) =
        (SELECT board.tileNumber 
        FROM board INNER JOIN specialsJunc ON board.tileNumber = specialsJunc.specialID 
        WHERE specialName = 'RAG_2')
        AND NEW.rolledNumber != 6;

    -- Update the audit table with the new credits value for the current player only
    UPDATE Audit
    SET currentCredits = (SELECT credits FROM Player WHERE id = NEW.playerid)
    WHERE auditID = NEW.auditID;
END;

-- TRIGGER BUILDING FEE UPDATE
CREATE TRIGGER buildingFeeUpdate
AFTER INSERT ON Audit
FOR EACH ROW
WHEN NEW.rolledNumber !=6
BEGIN 
-- Update building fee to purchase value (2*tuitionfee) if buildings of a color are owned by only one player
-- I group by color, then count the distinct ownedby, I also have a case where the count of ownedby is less than all counts
-- this means we have owner null (university), as a result, add 1. (in count, NULL is treated as 0 and this is misleading for my case)
-- (So that in a case of color owned by player1 and university it doesn't count it as 1 but 2)
UPDATE Building
	SET tuitionfee = purchaseValue
		WHERE color IN (
        SELECT color
        FROM Building
        GROUP BY color
        HAVING COUNT(DISTINCT ownedBy) + 
         (CASE WHEN COUNT(ownedBy) < COUNT(*) THEN 1 ELSE 0 END) = 1);
END;
-- TRIGGER FOR OWNERSHIP UPDATE
CREATE TRIGGER buildingOwnershipUpdate
AFTER INSERT ON Audit
FOR EACH ROW
WHEN NEW.rolledNumber != 6
BEGIN
    -- Update Building Ownership if it is not owned and the player has enough credits
    UPDATE Building
    SET ownedBy = 
        CASE
            WHEN Building.ownedBy IS NULL
                AND (SELECT credits FROM Player WHERE Player.id = NEW.playerid) >= 
                   (SELECT purchaseValue 
                    FROM Building 
                    WHERE buildingLocation = (SELECT currentLocation FROM Player WHERE id = NEW.playerid))
            THEN NEW.playerid
            ELSE Building.ownedBy
        END
    WHERE Building.buildingLocation = (SELECT currentLocation FROM Player WHERE Player.id = NEW.playerid);
END;
-- TRIGGER TO UPDATE BUILDING OWNERSHIP PURCHASE
CREATE TRIGGER buildingOwnershipUpdatePurchase
AFTER INSERT ON Audit
FOR EACH ROW
WHEN NEW.rolledNumber != 6
BEGIN
    -- Deduct credits from player for the Building purchase only if it was unowned before
    -- AND his credits >= than purchase value
    UPDATE Player
    SET credits = credits - (
        SELECT purchaseValue 
        FROM Building 
        WHERE buildingLocation = (SELECT currentLocation FROM Player WHERE id = NEW.playerid)
    )
    WHERE id = NEW.playerid 
    AND (SELECT ownedBy FROM Building 
         WHERE Building.buildingLocation = (SELECT currentLocation FROM Player WHERE id = NEW.playerid)) IS NULL
    AND (SELECT credits FROM Player WHERE id = NEW.playerid) >= (
        SELECT purchaseValue 
        FROM Building 
        WHERE buildingLocation = (SELECT currentLocation FROM Player WHERE id = NEW.playerid)
    );
    -- Update audit table to current credits of the player after buying
    UPDATE Audit 
        SET currentCredits = (SELECT credits FROM Player WHERE Player.id = NEW.playerid)
        WHERE Audit.playerid = NEW.playerid AND Audit.auditID = NEW.auditID;
END;
-- TRIGGER TO UPDATE SPECIAL STATUS OF PLAYER
CREATE TRIGGER specialStatusUpdate
AFTER INSERT ON audit
FOR EACH ROW
WHEN NEW.rolledNumber != 6
BEGIN 
    -- when location is not in the specialsJunc table then its 0, else 1 (using special true)
    UPDATE player
    SET isUsingSpecial = 
        CASE
            WHEN Player.currentLocation IN (
                SELECT specialID 
                FROM specialsJunc
            ) THEN 1
            ELSE 0
        END
    WHERE player.id = NEW.playerid;
END;
-- TRIGGER TO UPDATE STATUS OF PLAYER
CREATE TRIGGER statusUpdate
AFTER INSERT ON audit
FOR EACH ROW
BEGIN 
    UPDATE player
    SET currentPlayerStatus = 
        CASE
            -- WHEN old location is 17, then suspended
		    WHEN (SELECT oldLocation 
                 FROM Player
				 WHERE Player.id = NEW.playerid) + NEW.rolledNumber = 17 THEN 'suspended'
            -- WHEN he is suspended and didn't roll 6, keep it suspended
            WHEN Player.currentPlayerStatus = 'suspended' AND NEW.rolledNumber != 6 THEN 'suspended'    
            -- WHEN Player location is 7 but he is not suspended, consider him visiting                         
            WHEN Player.currentLocation = 7 AND Player.currentPlayerStatus != 'suspended' THEN 'visiting'
            -- when in Ali_g free resting
            WHEN Player.currentLocation = 10 THEN 'free_resting'
            ELSE 'active'
        END,
            -- Keep location in 7 if not rolled 6
		    currentLocation = 
            CASE
            WHEN currentPlayerStatus = 'suspended' AND NEW.rolledNumber != 6 THEN 7
            ELSE currentLocation 
        END
    WHERE player.id = NEW.playerid;
END;