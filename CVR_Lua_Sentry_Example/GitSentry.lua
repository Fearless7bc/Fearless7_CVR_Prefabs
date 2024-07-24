UnityEngine = require("UnityEngine")
CVR = require("CVR")
-- Start is called before the first frame update
function Start()
    -- Ensure your bound objects name are the same as these, for the corresponding objects
    Viewpoint = BoundObjects.Viewpoint -- The object in which it will check for players within the MaxAngle infront of it
    Animator = BoundObjects.Animator -- The animator, so we can sync what state the turret is in
    Spawnable = BoundObjects.Spawnable -- The spawnable script so we can change the sync values
    Target = BoundObjects.Target -- The target we set to the position of the tracked player, to have the turret aim constrained to
    RaycastChecker = BoundObjects.RaycastChecker.transform -- The raycast object we use to detect if we have Line of Sight (LOS) to the tracked player
    SyncAttach = BoundObjects.SyncAttach:CustomTrigger() -- Used to make the "Target" object synced, we have to attach something to the prop spawner. This is to ONLY attach to the prop spawner
    MaxAngle = 40 -- Max angle left or right of the Viewpoint it will detect players
    MaxRange = 15 -- The max range it will target a player
end

-- Function to get the player the turret is aiming at within a N-degree angle
function DistanceSort(a, b)
    return (a.distance < b.distance)
end

function GetTargetedPlayer(position, forward, maxAngle)
    -- Fill own table and sort players by distance from close to far away
    local distanceTable = {}
    for _,v in ipairs(PlayerAPI.AllPlayers) do -- v is the player
        --if not v.IsLocal then -- This makes it ignore the prop spawner. Uncomment out to ignore the prop spawner as a target
            local playerPoint = (v.GetPosition() + v.GetViewPointPosition()) * 0.5 -- player's center
            local playerDistance = UnityEngine.Vector3.Distance(playerPoint, position)
            table.insert(distanceTable, { player = v, point = playerPoint, distance = playerDistance })
        --end
    end
    table.sort(distanceTable, DistanceSort)
    
    local targetedPlayer = false
    for _,v in ipairs(distanceTable) do -- v is the player
        RaycastChecker.transform.rotation = UnityEngine.Quaternion.LookRotation(v.point - RaycastChecker.transform.position)

        local hitInfo = Raycast() -- Raycast checks if it lands farther than the player, if it does it has LOS. If it lands short then it hit a wall.
        local hitPoint = hitInfo.point
        local distanceRaycastCheck = UnityEngine.Vector3.Distance(RaycastChecker.position, hitPoint)
        local distancePlayer = UnityEngine.Vector3.Distance(RaycastChecker.position, v.player.GetPosition())
        local playerAngle = UnityEngine.Vector3.Angle(forward, v.point - position)

        if distanceRaycastCheck >= distancePlayer and playerAngle <= maxAngle then
            targetedPlayer = v.player -- Returns the player if they are within LOS, and within View angle
            break
        end
    end
    -- Specific case when it can fail: first nearest player is shorter than second nearest player
    return targetedPlayer
end

function Raycast()
    -- Define the maximum distance for the raycast (this should be greater than your max range)
    local maxDistance = MaxRange + 100.0
    -- Used for the raycast, so it only hits colliders on the default layer
    local onlyDefaultMask = bit32.lshift(1, CVR.CVRLayers.Default)

    local origin = RaycastChecker.position
    local forward = RaycastChecker.rotation * UnityEngine.Vector3.forward

    -- Shoot a raycast from the playe's view point, that can hit the layers Default and remotePlayers, and hits colliders with IsTrigger enabled
    local hit, hitInfo = UnityEngine.Physics.Raycast(origin, forward, maxDistance, onlyDefaultMask, UnityEngine.QueryTriggerInteraction.Ignore)
 
    -- Check if the raycast hit something
    if hit == false then
        return hitInfo
    end
    if hit == true then
        return hitInfo
    end
end

-- Update is called once per frame
function Update()
    -- Usage
    local viewPosition = BoundObjects.Viewpoint.transform.position-- The Viewpoint's position
    local viewForward = BoundObjects.Viewpoint.transform.forward-- The Viewpoint's forward direction (it returns)
    
    Player = GetTargetedPlayer(viewPosition, viewForward, MaxAngle)

    if(Player) then -- If player is returned from GetTargetPlayer function
        local playerPos = Player.GetPosition()
        local playerViewPos = Player.GetViewPointPosition()
        local playerMiddle = (playerViewPos.y - playerPos.y) / 2
        local distanceFrom = UnityEngine.Vector3.Distance(playerPos, Viewpoint.transform.position) -- Distance from turret
        if Animator.GetFloat("TrackState") <= 1 then -- If in search or locked state, target nearest player within LOS
            if distanceFrom <= MaxRange then -- If within range target player

                -- Description of how to use this: Spawnable.SetValue("The parameter index on the spawnable script", "Value to set parameter to").
                Spawnable.SetValue(0,1) -- If in range, locks onto player
                Target.transform.position = UnityEngine.NewVector3(playerPos.x, playerPos.y + playerMiddle, playerPos.z) -- Sets the target object to the targeted player's position
            else
                Spawnable.SetValue(0,0)-- If out of range, unlocks from player, enters search
            end
        end
    else
        Spawnable.SetValue(0,0) -- If no player is given, stays in search
    end
end
