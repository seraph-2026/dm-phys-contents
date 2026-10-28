
mob
	icon = 'Icons.dmi'
	icon_state = "Player"

	Login()
		src.loc = locate(50,50,1)
		src.phys_contents.add(new/obj/air_ship(), 0, 1)
		src.phys_contents.add(new/obj/air_ship(), 0, -1)
		src.phys_contents.add(new/obj/air_ship(), 1, 0)
		src.phys_contents.add(new/obj/air_ship(), -1, 0)

world
	view = 15
	fps = 30

obj/air_ship
	icon = 'Icons.dmi'
	icon_state = "Airship"
	density = 1

turf/grass
	icon = 'Icons.dmi'
	icon_state = "Grass"

turf/tree
	icon = 'Icons.dmi'
	icon_state = "Tree"
	density = 1