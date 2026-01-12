RemoteEvents required under Panda ReplicatedStorage/Emotes_Sync/Events

Create the following RemoteEvent objects in Roblox Studio (no server-side code here):

- PlayAnimation (RemoteEvent)
- StopAnimation (RemoteEvent)
- Sync (RemoteEvent)              -- Receives: (player, "sync", targetPlayer) or (player, "unsync")
- AnimationPlayer (RemoteEvent)  -- Optional, if you use a dedicated animation player
- UpdatePinnedDances (RemoteEvent)
- PropSignal (RemoteEvent)

Optional notification remote (server -> client):
- SyncNotify (RemoteEvent)       -- Fire to client: (success:boolean, message:string, type:string)

Notes:
- Some scripts expect PlayAnimation and StopAnimation under the Emotes_Sync root (not inside Events); if so, create RemoteEvents there as well or update scripts to use the Events folder.
- Replace these placeholders in Roblox Studio by creating RemoteEvent instances (no Lua file required).
