
#define ICON_SIZE_X 32
#define ICON_SIZE_Y 32

/**
 * Every atom keeps tack of it's physical contents parent
 */
atom
	/**
	 * Public
	 */
	var/atom/movable/phys_parent

/**
 * Makes phys_contents available on atom/movable types
 */
atom/movable
	/**
	 * Public
	 */
	var/phys_contents/phys_contents // Used similar to vis_contents
	
	/**
	 * Private
	 */
	var/atom/movable/_physVisClone // 
	var/_physLastSavedLoc // Used if steps fail


	New()
		..()
		phys_contents = new/phys_contents(src)

atom/movable
	/**
	 * Move all phys contents when parent atom moves
	 * 
	 * Fail the total move if any children fail to move
	 */
	Move(NewLoc, Dir, step_x, step_y)
		
		// Check for physical contents and move it first
		if(phys_contents.contents.len)

			var/physContentsMoveResult = phys_contents.Move(NewLoc, Dir, step_x, step_y)
			
			if(!physContentsMoveResult)
				return 0

		// Now move the parent
		var/playerMoveResult = ..() // Move player

		// If the player failed to move, then revert the physical contents back as well
		if(!playerMoveResult)
			phys_contents.reverseMove()
			phys_contents.clearSavedPositions()
			return 0
		
		// Otherwise return the parents move result
		else
			phys_contents.clearSavedPositions()
			return playerMoveResult

	/**
	 * Atoms that are part of the same phys_contents can cross paths
	 * 
	 * Atoms that are parents of phys_contents can cross paths
	 * 
	 * Atoms that are children of phys_contents can cross paths
	 */
	Cross(var/atom/a)
		if(a.phys_parent == src.phys_parent || a == src.phys_parent || a.phys_parent == src)
			return TRUE
		else
			return ..()
	

/**
 * Phys contents is like vis_contents but they are physically real objects
 */
phys_contents
	var
		atom/movable/phys_parent
		list/contents = list()
		vis_contents = list()

	/**
	 * phys_contents keeps track of the parent
	 */
	New(var/atom/movable/a)
		phys_parent = a

	/**
	 * Move all phys contents objects in the direction the parent moved
	 */
	proc/Move(NewLoc, Dir, step_x, step_y)

		for(var/atom/movable/childAtom in contents)
			// Allow us to revert if any failed steps are found
			childAtom._physLastSavedLoc = childAtom.loc

			// Attempt child atom step
			var/stepResult = step(childAtom, Dir)
			
			// Failed step attempt
			if(!stepResult)

				src.reverseMove()

				// Failed total move
				return 0
		
		// Successful move
		return 1
	
	/**
	 * Allows you to completely reverse a movement of any physical contents
	 */
	proc/reverseMove()
		// Reverse all child atom steps
		for(var/atom/movable/childAtom in contents)
			if(childAtom._physLastSavedLoc)
				childAtom.loc = childAtom._physLastSavedLoc

	/**
	 * Once a move has been completed, the saved locations are stale and need to be removed
	 */
	proc/clearSavedPositions()
		// Reverse all child atom steps
		for(var/atom/movable/childAtom in contents)
			childAtom._physLastSavedLoc = null

	/**
	 * Add any atom to the physical contents of another
	 * 
	 * Tile x and y are coordinates, with their center at the phys_contents parent.
	 */
	proc/add(var/atom/movable/someAtom, var/tile_x, var/tile_y)
		/**
		 * Keep the physically real version in contents and clone a version for the vis_contents
		 */
		var/atom/movable/visCloneA = new someAtom.type()
		contents += someAtom
		vis_contents += visCloneA

		/**
		 * Positions visual contents relative to the parent's position
		 * 
		 * (0, 1) is 1 tile north of the parent.
		 */
		visCloneA.pixel_x = tile_x * ICON_SIZE_X
		visCloneA.pixel_y = tile_y * ICON_SIZE_Y
		phys_parent.vis_contents += visCloneA

		/**
		 * Positions physical contents relative to parent's position
		 */
		locateRelativeToParent(phys_parent.x + tile_x, phys_parent.y + tile_y, phys_parent.z)

		// Make inviisble
		someAtom.alpha = 0

		// Track the parent
		someAtom.phys_parent = src.phys_parent

	/**
	 * Positions atom/movable relative to phys_contents parent's position
	 * 
	 * x, y, z are measured in tiles
	 */
	proc/locateRelativeToParent(var/atom/movable, x, y, z)
		
		 someAtom.loc =locate(phys_parent.x + tile_x, phys_parent.y + tile_y, phys_parent.z)
		
	/**
	 * Remove any atom from the physical contents of another
	 */
	proc/remove(var/atom/movable/someAtom)
		contents -= someAtom
		vis_contents -= someAtom.phys_vis_clone
		someAtom.phys_parent = null

		// Make visible again
		someAtom.alpha = 255 
		


