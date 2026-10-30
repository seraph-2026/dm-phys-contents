
mob
	/**
	 * Required for opacity to work with this library.
	 */
	sight = SEE_PIXELS

atom/movable
	/**
	 * For physical contents to move together in sync, this needs to be enabled
	 *
	 * It can be overriden, but that will introduce possible stuttering in some cases.
	 */
	animate_movement = SYNC_STEPS

	/**
	 * All atom/movable get a physical contents
	 */
	var/phys_contents/phys_contents

	/**
	 * All atom/movable can have a phys_parent
	 */
	var/atom/movable/phys_parent

	New()
		..()
		phys_contents = new(src) // Set phys_parent

	/**
	 * All atom/movable can be positioned in a phys_contents
	 *
	 * This is relative to their phys_parent
	 *
	 * Setting these directly won't do anything
	 */
	var/phys_x = 0
	var/phys_y = 0
	var/phys_z = 0

	/**
	 * Some atoms in physical contents represent border elements.
	 *
	 * This means the elements are not surrounded on all sides by other members of the same phys_contents.
	 *
	 * This means they touch things which are not phys_contents and need to Bump() check.
	 *
	 * For elements that are not border elements, they have all sides (NSEW) containing elements of the same phys contents.
	 *
	 * This means their next move is guarnteed to be a success and we just edit their location rather than doing all the bump checks.
	 */
	var/phys_isBorder = 0

	/**
	 * Used to set loc relative to phys_contents parent
	 */
	proc/physLoc(var/x, var/y, var/z = 0)
		if(!phys_parent) throw EXCEPTION("Attempted to use physLoc() on [src] which isn't in the physical contents of anything.")

		phys_x = x
		phys_y = y
		phys_z = z

		loc = locate(
			phys_parent.x + phys_x,
			phys_parent.y + phys_y,
			phys_parent.z + phys_z
		)

	/**
	 * When atom with phys_contents moves, all contents move
	 */
	Move(var/atom/NewLoc, Dir, step_x, step_y)

		// Move all _borderElements and stop if blocked
		for(var/atom/movable/borderElement in src.phys_contents._borderElements)

			// Phys elements need to position relative to the NewLoc
			var/childNewLoc = locate(
				NewLoc.x + borderElement.phys_x,
				NewLoc.y + borderElement.phys_y,
				NewLoc.z + borderElement.phys_z
			)

			/**
			 * Attempt to move the border element.
			 */
			if(borderElement.phys_isBorder)
				var/moveResult = borderElement.Move(childNewLoc, Dir, step_x, step_y)

				if(!moveResult)
					_resetBorderElementPositions()
					return 0

		var/parentMoveSuccess = ..(NewLoc, Dir, step_x, step_y)
		if(!parentMoveSuccess)
			_resetBorderElementPositions()

		/**
		 * Border elements & the parent successfully moved
		 *
		 * Inner elements can now move directly, as an optimization to skip redundant movement procs
		 *
		 * These are always successful
		 */
		else
			// Move all inner elements
			for(var/atom/movable/innerElement in src.phys_contents._innerElements)

				var/childNewLoc = locate(
					src.loc.x + innerElement.phys_x,
					src.loc.y + innerElement.phys_y,
					src.loc.z + innerElement.phys_z
				)

				// Directly set the location for an optimization boost
				innerElement.loc = childNewLoc
				innerElement.step_x = src.step_x
				innerElement.step_y = src.step_y
				innerElement.dir = Dir

		// Return relevant success data
		return parentMoveSuccess

	/**
	 * Physical contents can cross themselves and their parents freely
	 */
	Cross(var/atom/someAtom)
		if(ismovable(someAtom))
			var/atom/movable/someMovableAtom = someAtom
			if(someMovableAtom.phys_parent == src.phys_parent || someMovableAtom.phys_parent == src || someMovableAtom == src.phys_parent)
				return 1

	/**
	 * Private
	 *
	 * Resets the position of each element back to relative to the parents current position
	 */
	proc/_resetBorderElementPositions()
		// Reset all phys contents in total
		for(var/atom/movable/movedElement in src.phys_contents._borderElements)
			movedElement.physLoc(movedElement.phys_x, movedElement.phys_y, movedElement.phys_z)
			movedElement.step_x = src.step_x
			movedElement.step_y = src.step_y

phys_contents
	/**
	 * All the atom/movable elements in the physical contents
	 */
	var/list/elements = list()
	var/atom/movable/owner

	/**
	 * Physical contents is internally reprsented as a conjunction of two lists
	 *
	 * Border and inner elements. This is used for optimization because inner elements are guarnteed to move successfully but
	 * only if all the border elements moved successfully.
	 *
	 * A border element has neighboring tiles that don't contain atoms with this phys_parents
	 * An inner element has all neighboring tiles contaiing atoms of this phy_parent
	 *
	 */
	var/list/_borderElements = list()
	var/list/_innerElements = list()

	New(var/atom/movable/owner)
		src.owner = owner

	/**
	 * Adds an atom/movable to a physical contents
	 */
	proc/add(var/atomOrList)
		if(islist(atomOrList))
			var/list/listOfAtoms = atomOrList
			for(var/atom/movable/someAtom in listOfAtoms)
				_addSingleElement(someAtom)

		else if(ismovable(atomOrList))
			var/atom/movable/someAtom = atomOrList
			_addSingleElement(someAtom)

		else
			throw EXCEPTION("phys_contents expects .add() to recieve a list or atoms, or a single atom. Actually got ([atomOrList])")

	/**
	 * Private
	 *
	 * Adds a single element only
	 */
	proc/_addSingleElement(var/atom/movable/someAtom)

		// Place the atom
		elements += someAtom
		someAtom.phys_parent = owner
		someAtom.physLoc(0, 0, 0)

		// Border managment for optimization
		_decideIsBorder(someAtom)
		_updateNeighborBorders(someAtom)


	/**
	 * Private
	 *
	 * Sets the phys_isBorder value of the object based on what atoms of the same phys_parent are around it.
	 *
	 * If all directions contains atoms of the same phys_parent then it's not a border.
	 *
	 * If any direcitons are missing an element of the same phys_parent, then it's a border
	 */
	proc/_decideIsBorder(var/atom/movable/someAtom)

		sleep(world.tick_lag) // Gives enough time for any neighboring tiles have moved otherwise it causes desync in the border process

		var/north = _locContainsPhysElement(get_step(someAtom, NORTH), someAtom.phys_parent)
		var/south = _locContainsPhysElement(get_step(someAtom, SOUTH), someAtom.phys_parent)
		var/east = _locContainsPhysElement(get_step(someAtom, EAST), someAtom.phys_parent)
		var/west = _locContainsPhysElement(get_step(someAtom, WEST), someAtom.phys_parent)
		var/northEast = _locContainsPhysElement(get_step(someAtom, NORTHEAST), someAtom.phys_parent)
		var/northWest = _locContainsPhysElement(get_step(someAtom, NORTHWEST), someAtom.phys_parent)
		var/southEast = _locContainsPhysElement(get_step(someAtom, SOUTHEAST), someAtom.phys_parent)
		var/southWest = _locContainsPhysElement(get_step(someAtom, SOUTHWEST), someAtom.phys_parent)

		// If it was already stored in a category, it's going to get replaced
		_innerElements -= someAtom
		_borderElements -= someAtom

		if(north && south && east && west && northEast && northWest && southEast && southWest)
			someAtom.phys_isBorder = 0
			_innerElements += someAtom

		else
			someAtom.phys_isBorder = 1
			_borderElements += someAtom




	/**
	 * Private
	 *
	 * It's possible the neighbors of an atom need to have their border status updated when adding or removing atoms.
	 *
	 * This wil update the status of all neighboring atoms of the same phys_parents
	 */
	proc/_updateNeighborBorders(var/atom/movable/someAtom)
		// Based on the new addition, surrounding atoms need to be rechecked.
		for(var/atom/borderingAtom in oview(1, someAtom))
			if(ismovable(borderingAtom))
				var/atom/movable/borderingAtomMovable = borderingAtom
				if(borderingAtomMovable.phys_parent == someAtom.phys_parent)
					_decideIsBorder(borderingAtomMovable)

	/**
	 * Private
	 *
	 * Returns true if loc contains members of phys_parent
	 */
	proc/_locContainsPhysElement(var/atom/loc, var/phys_parent)
		for(var/locItem in loc)
			if(istype(locItem, /atom/movable))
				var/atom/movable/atomLocItem = locItem
				if(atomLocItem.phys_parent == phys_parent)
					return 1

	/**
	 * Change += to add()
	 */
	proc/operator+=(var/someInput)
		src.add(someInput)

	/**
	 * Removes an atom/movable from a physical contents
	 */
	proc/remove(var/atomOrList)

		if(islist(atomOrList))
			var/list/listOfAtoms = atomOrList
			for(var/atom/movable/someAtom in listOfAtoms)
				_removeSingleElement(someAtom)

		else if(ismovable(atomOrList))
			var/atom/movable/someAtom = atomOrList
			_removeSingleElement(someAtom)

		else
			throw EXCEPTION("phys_contents expects .remove() to recieve a list or atoms, or a single atom. Actually got ([atomOrList])")
	/**
	 * Change -= to remove()
	 */
	proc/operator-=(var/someInput)
		src.remove(someInput)

	/**
	 * Private
	 *
	 * Removes a single element only
	 */
	proc/_removeSingleElement(var/atom/movable/someAtom)
		// Remove element
		elements -= someAtom
		someAtom.phys_parent = null

		// Border managment for optimization
		_innerElements -= someAtom
		_borderElements -= someAtom
		_updateNeighborBorders(someAtom)