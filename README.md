# DM Physical Contents

# Brief summary
This library adds a new variable to ```atom``` called ```phys_contents``` which functions exactly like ```vis_contents```, only the contents are physically real, having density and map prescence.

When your atom moves, the physical contents move with it.

That means you can easily build things like cars, boats or planes that are made from multiple tiles.

## Adding an object to phys_contents
This will place ```bike``` at the location of ```player```, where it will now move in step with it.
```java
var/obj/bike = new/obj/bike()
player.phys_contents += someObj
```
## How to position elements
Sometimes you want to position elements relative to the player. This is how you do it.
```java
var/obj/boat/leftSection = new/obj/boat()
var/obj/boat/middleSection = new/obj/boat()
var/obj/boat/rightSection = new/obj/boat()

player.phys_contents += list(leftSection, middleSection, rightSection)

// Places boat pieces left center and right of the player. That move along with it
leftSection.physLoc(-1, 0, 0)
middleSection.physLoc(0, 0, 0)
rightSection.physLoc(1, 0, 0)
```
The key is ```physLoc``` which accepts (x, y, z) coordinate offsets relative to the owner of the phys_contents

## How to remove an object
It's very plain and simply to do so.
```java
player.phys_contents -= leftSection
player.phys_contents -= list(leftSection, middleSection, rightSection)
```
## How to access physical contents
If you want to see a list of all the contents of phys_contents this is how you'd do it
```java
for(var/atom/movable/someAtom in player.phys_contents.elements)
	world << "[a.type]"
```
