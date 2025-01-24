INSERT INTO Board (tileNumber, tileType) VALUES
(0,"Special");
INSERT INTO Board (tileType) VALUES
("Building"),
("Building"),
("Special"),
("Building"),
("Building"),
("Special"),
("Special"),
("Building"),
("Building"),
("Speciall"),
("Building"),
("Building"),
("Special"),
("Building"),
("Building"),
("Speciall"),
("Special"),
("Building"),
("Building");

INSERT INTO Tokens (name, isAvailable) VALUES
("Mortarboard",0),
("Book", 0),
("Certificate", 0),
("Gown", 1),
("Laptop", 1),
("Pen", 0);
INSERT INTO Player (id, name, credits, chosenToken, currentLocation,
                    currentPlayerStatus, isUsingSpecial, oldLocation) 
VALUES
(1,"Gareth",345,"Certificate",18,"active",0,NULL),
(2,"Uli",590,"Mortarboard",1,"active",0,NULL),
(3,"Pradyumn",465,"Book",5,"active",0,NULL),
(4,"Ruth",360,"Pen",3,"active",1,NULL);


INSERT INTO Building (buildingLocation, buildingName,
					tuitionfee, ownedBy, purchaseValue, color) 
VALUES
(1,"Kilburn",15,4, 30,"Green"),
(2,"IT",15,1, 30,"Green"),
(4,"Uni_Place",25,1,50,"Orange"),
(5,"AMBS", 25,2,50,"Orange"),

(8,"Crawford",30,3, 60,"Blue"),
(9,"Sugden",30,1,60,"Blue"),
(11,"Shopping_Precinct",35,NULL,60,"Brown"),
(12,"MECD", 35,2,70,"Brown"),

(14,"Library",40,3, 80,"Gray"),
(15,"Sam_Alex",40,NULL,80,"Gray"),

(18,"Museum",50,3,100,"Black"),
(19,"Whitworth_Hall", 50,4,100,"Black");


INSERT INTO SpecialsDesc (specialName, specialDescription) VALUES
("Welcome_Week", "Awarded 100 credits"),
("Hearing_1", "You are found guilty of academic malpractice, Fined 20 credits"),
("RAG_1", "You win a fancy dress competition, Awarded 15 credits"),
("Suspension", "Player is sent here if landed on Your'e Suspended, if player not suspended, player is considered visiting"),
("Ali_G", "Free Resting"),
("RAG_2", "You receive bursary and share it with your friends. Give all other players 10 credits"),
("Hearing_2", "You are in rent arrears, Fined 25 credits"),
("Your'e Suspended", "Move to Suspension location. Player rolls again, Roll 6 to break free.");

INSERT INTO SpecialsJunc (specialID, specialName) VALUES
(0,"Welcome_Week"),
(3,"Hearing_1"),
(6,"RAG_1"),
(7,"Suspension"),
(10,"Ali_G"),
(13,"RAG_2"),
(16,"Hearing_2"),
(17,"Your'e Suspended");

