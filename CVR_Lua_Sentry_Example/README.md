## Preview
![Preview (2)](https://github.com/user-attachments/assets/1c783196-89a3-477f-bd89-80ebd716c6b9)

## Description
The prop will target any player within it's field of vision. Then track that player until it leaves the field.
Also it will do a line of sight (LOS) check, using a raycast.
It will track the player while firing a particle at them.

## Technical Details
- It will look for players within a max angle infront of the Viewpoint. By default it is 40 degrees.
- It will confirm if it has line of sight (LOS) to the player, using the raycast.
- It will only track players within it's max range too, by default it is 15.
- It will change one synced parameter, the first one in the spawnable script, to the value 1 when tracking a player. It will be 0 when not tracking a player.
- There is an object that will attach to the prop spawner, this is to force it to sync the position of the target object.

## Requirements
You need to have the CVR experimental CCK. It can be found in the official ABI Discord.
