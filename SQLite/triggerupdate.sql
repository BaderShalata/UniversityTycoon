CREATE TRIGGER creditsUpdate
AFTER INSERT ON audit
FOR EACH ROW
BEGIN
    -- Update player credits for the player who just moved
    UPDATE player
    SET credits =
        CASE
            WHEN (SELECT currentLocation FROM player WHERE id = NEW.playerid) = 0
            THEN credits + 100
            -- IF PLAYER ENTER A NEW CYCLE BUT LANDED ON OWNED BUILDING
            WHEN (SELECT currentLocation FROM player WHERE id = NEW.playerid) < (SELECT oldLocation FROM player WHERE id = NEW.playerid)
                AND (SELECT currentPlayerStatus FROM player WHERE id = NEW.playerid) != 'suspended'
                AND (SELECT ownedBy FROM building WHERE buildingLocation = (SELECT currentLocation FROM player WHERE id = NEW.playerid)) IS NOT NULL
                AND (SELECT ownedBy FROM building WHERE buildingLocation = (SELECT currentLocation FROM player WHERE id = NEW.playerid)) != NEW.playerid
            THEN credits + 100 - (SELECT tuitionfee FROM building WHERE buildingLocation = (SELECT currentLocation FROM player WHERE id = NEW.playerid))
            -- IF PLAYER ENTER A NEW CYCLE BUT LANDED ON UNOWNED BUILDING
            WHEN (SELECT currentLocation FROM player WHERE id = NEW.playerid) < (SELECT oldLocation FROM player WHERE id = NEW.playerid)
                AND (SELECT currentPlayerStatus FROM player WHERE id = NEW.playerid) != 'suspended'
                AND (SELECT ownedBy FROM building WHERE buildingLocation = (SELECT currentLocation FROM player WHERE id = NEW.playerid)) IS NULL
                AND (SELECT ownedBy FROM building WHERE buildingLocation = (SELECT currentLocation FROM player WHERE id = NEW.playerid)) != NEW.playerid
            THEN credits + 100 - (SELECT purchaseValue FROM building WHERE buildingLocation = (SELECT currentLocation FROM player WHERE id = NEW.playerid))
            -- IF PLAYER ENTER A NEW CYCLE BUT LANDED ON HIS OWN
            WHEN (SELECT currentLocation FROM player WHERE id = NEW.playerid) < (SELECT oldLocation FROM player WHERE id = NEW.playerid)
                AND (SELECT currentPlayerStatus FROM player WHERE id = NEW.playerid) != 'suspended'
                AND (SELECT ownedBy FROM building WHERE buildingLocation = (SELECT currentLocation FROM player WHERE id = NEW.playerid)) IS NOT NULL
                AND (SELECT ownedBy FROM building WHERE buildingLocation = (SELECT currentLocation FROM player WHERE id = NEW.playerid)) != NEW.playerid
            THEN credits + 100
            -- Tuition fee if rolled number is not 6 and building is owned by someone else
            WHEN NEW.rolledNumber != 6
                AND (SELECT ownedBy FROM building WHERE building.buildingLocation = (SELECT currentLocation FROM player WHERE id = NEW.playerid)) IS NOT NULL
                AND (SELECT ownedBy FROM building WHERE building.buildingLocation = (SELECT currentLocation FROM player WHERE id = NEW.playerid)) != NEW.playerid
            THEN credits - (SELECT tuitionfee FROM building WHERE building.buildingLocation = (SELECT currentLocation FROM player WHERE id = NEW.playerid))
            -- IF PLAYER LANDS ON HIS BUILDING
                       WHEN NEW.rolledNumber != 6
                AND (SELECT ownedBy FROM building WHERE building.buildingLocation = (SELECT currentLocation FROM player WHERE id = NEW.playerid)) IS NOT NULL
                AND (SELECT ownedBy FROM building WHERE building.buildingLocation = (SELECT currentLocation FROM player WHERE id = NEW.playerid)) = NEW.playerid
            THEN credits

            -- Handling Hearing penalties
            WHEN NEW.rolledNumber != 6 AND (SELECT currentLocation FROM player WHERE id = NEW.playerid) =
                (SELECT board.tileNumber FROM board INNER JOIN specialsJunc ON board.tileNumber = specialsJunc.specialID WHERE specialName = 'Hearing_1')
            THEN credits - 20

            WHEN NEW.rolledNumber != 6 AND (SELECT currentLocation FROM player WHERE id = NEW.playerid) =
                (SELECT board.tileNumber FROM board INNER JOIN specialsJunc ON board.tileNumber = specialsJunc.specialID WHERE specialName = 'Hearing_2')
            THEN credits - 25

            -- RAGS rewards
            WHEN NEW.rolledNumber != 6 AND (SELECT currentLocation FROM player WHERE id = NEW.playerid) =
                (SELECT board.tileNumber FROM board INNER JOIN specialsJunc ON board.tileNumber = specialsJunc.specialID WHERE specialName = 'RAG_1')
            THEN credits + 15

            WHEN NEW.rolledNumber != 6 AND (SELECT currentLocation FROM player WHERE id = NEW.playerid) =
                (SELECT board.tileNumber FROM board INNER JOIN specialsJunc ON board.tileNumber = specialsJunc.specialID WHERE specialName = 'RAG_2')
            THEN credits - (SELECT COUNT(*) - 1 FROM player) * 10

            -- If none of the conditions are met, retain current credits
            ELSE credits
        END
    WHERE id = NEW.playerid;

    UPDATE player
    SET credits = credits +
        (SELECT tuitionfee FROM building WHERE buildingLocation =
        (SELECT currentLocation FROM player WHERE id = NEW.playerid))
    WHERE id =
        (SELECT ownedBy FROM building WHERE buildingLocation =
        (SELECT currentLocation FROM player WHERE id = NEW.playerid))
    AND SELECT ownedBy FROM building WHERE buildingLocation =
                (SELECT currentLocation FROM player WHERE id = NEW.playerid)) != NEW.playerid
    AND (SELECT ownedBy FROM building WHERE buildingLocation =
        (SELECT currentLocation FROM player WHERE id = NEW.playerid)) IS NOT NULL;
-- player pays fee if he lands on his building!
    -- Add 10 credits to every other player
    UPDATE player
    SET credits = credits + 10
    WHERE id != NEW.playerid AND (SELECT currentLocation FROM player WHERE id = NEW.playerid) =
        (SELECT board.tileNumber FROM board INNER JOIN specialsJunc ON board.tileNumber = specialsJunc.specialID WHERE specialName = 'RAG2');

    -- Update the audit table with the new credits value
    UPDATE audit
    SET currentCredits = (SELECT credits FROM player WHERE id = NEW.playerid)
    WHERE playerid = NEW.playerid AND roundNumber = NEW.roundNumber;
END;



