
#define ICON_SIZE_X 32
#define ICON_SIZE_Y 32

/**
 * Every atom keeps tack of it's physical contents parent
 */
atom
	var/atom/movable/phys_parent

/**
 * Atom movables now have phys_contents
 */
atom/movable
	var/phys_contents/phys_contents // Used similar to vis_contents
	var/phys_saved_icon // Used to save the icon this uses
	var/atom/movable/phys_vis_clone // 
	var/phys_lastSavedLoc // Used if steps fail

	/**
	 * Every atom gets a phys contents
	 */
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
			childAtom.phys_lastSavedLoc = childAtom.loc

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
			if(childAtom.phys_lastSavedLoc)
				childAtom.loc = childAtom.phys_lastSavedLoc

	/**
	 * Once a move has been completed, the saved locations are stale and need to be removed
	 */
	proc/clearSavedPositions()
		// Reverse all child atom steps
		for(var/atom/movable/childAtom in contents)
			childAtom.phys_lastSavedLoc = null

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
		//phys_parent.vis_contents += visCloneA

		/**
		 * Positions physical contents relative to parent's position
		 */
		someAtom.loc = locate(phys_parent.x + tile_x, phys_parent.y + tile_y, phys_parent.z)

		// Remove the physical appearance but save it
		someAtom.phys_saved_icon = someAtom.icon
		//someAtom.icon = null

		// Track the parent
		someAtom.phys_parent = src.phys_parent

		// Now there's a visual representation and an invisible physical representation

		
	/**
	 * Remove any atom from the physical contents of another
	 */
	proc/remove(var/atom/movable/someAtom)
		/**
		 * Remove from visual and physical contents and reset its icon
		 */
		contents -= someAtom
		vis_contents -= someAtom.phys_vis_clone
		someAtom.icon = someAtom.phys_saved_icon

		// Remove parent tracking
		someAtom.phys_parent = null
		


