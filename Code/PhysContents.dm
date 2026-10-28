

atom/movable
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
	 * Used to set loc relative to phys_contents parent
	 */
	proc/physLoc(var/x, var/y, var/z = 0)
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

		var/list/movedElements = list()
		
		// Move all phys_contents and stop if blocked
		for(var/atom/movable/element in src.phys_contents.elements)

			// Phys elements need to position relative to the NewLoc
			var/childNewLoc = locate(
				NewLoc.x + element.phys_x, 
				NewLoc.y + element.phys_y,
				NewLoc.z + element.phys_z
			)
			
			var/moveResult = element.Move(childNewLoc, Dir, step_x, step_y)

			movedElements += element

			if(!moveResult)
				// Reset all phys contents that moved
				for(var/atom/movable/movedElement in movedElements)
					movedElement.physLoc(movedElement.phys_x, movedElement.phys_y, movedElement.phys_z)
				
				return 0

		var/parentMoveSuccess = ..(NewLoc, Dir, step_x, step_y)
		if(!parentMoveSuccess)
			// Reset all phys contents in total
			for(var/atom/movable/movedElement in movedElements)
				movedElement.physLoc(movedElement.phys_x, movedElement.phys_y, movedElement.phys_z)

		return parentMoveSuccess
	
	/**
	 * Physical contents can cross themselves and their parents freely
	 */
	Cross(var/atom/someAtom)
		if(ismovable(someAtom))
			var/atom/movable/someMovableAtom = someAtom
			if(someMovableAtom.phys_parent == src.phys_parent || someMovableAtom.phys_parent == src || someMovableAtom == src.phys_parent)
				return 1

phys_contents
	/**
	 * All the atom/movable elements in the physical contents
	 */
	var/list/elements = list()
	var/atom/movable/owner

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
		elements += someAtom
		someAtom.phys_parent = owner
		someAtom.animate_movement = SYNC_STEPS
		someAtom.physLoc(0, 0, 0)

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
		elements -= someAtom
		someAtom.phys_parent = null
		someAtom.animate_movement = FORWARD_STEPS 

