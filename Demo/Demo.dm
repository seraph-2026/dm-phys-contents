
mob
	icon = 'Icons.dmi'
	icon_state = "Player"
	density = 1

	Login()
		src.loc = locate(50,50,1)
		addBoat(3, 2)

	proc
		/**
		 * Consturcts a boat of an arbitrary size
		 * 
		 * Appends it to physical contents so it moves with the player
		 */
		addBoat(var/width, var/height)
			for(var/xLoc in -width to width)
				for(var/yLoc in -height to height)
					var/obj/boat/boatPiece = new/obj/boat()
					src.phys_contents += boatPiece
					boatPiece.physLoc(xLoc, yLoc, 0)

world
	view = 15
	fps = 25

obj/boat
	icon = 'Icons.dmi'
	icon_state = "Boat"
	density = 1

turf/water
	icon = 'Icons.dmi'
	icon_state = "Water"

turf/rock
	icon = 'Icons.dmi'
	icon_state = "Rock"
	density = 1