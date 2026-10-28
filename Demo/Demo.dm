
mob
	icon = 'Icons.dmi'
	icon_state = "Player"
	density = 1
	step_size = 4

	Login()
		src.loc = locate(50,50,1)

		var/obj/boat/leftSection = new/obj/boat()
		var/obj/boat/middleSection = new/obj/boat()
		var/obj/boat/rightSection = new/obj/boat()

		src.phys_contents += list(leftSection, middleSection, rightSection)

		leftSection.physLoc(-1, 0, 0)
		middleSection.physLoc(0, 0, 0)
		rightSection.physLoc(1, 0, 0)


world
	view = 15
	fps = 30

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