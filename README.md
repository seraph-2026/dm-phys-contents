# DM Physical Contents

Adds a new variable to DM called
```java
atom.phys_contents
```

## How to add an object
```java
atom.phys_contents.add(new/obj/someObj, 0, 1)
```
The coordinates 0, 1 are relative positions to the parent atom in tiles.

## How to remove an object
If someObj is in the contents, it can be removed like so.
```java
atom.phys_contents.remove(someObj)
```
## How to access physical contents
If you want to see a list of all the contents of phys_contents this is how you'd do it
```java
for(var/atom/movable/a in atom.phs_contents.contents)
	world << "[a.type]"
```