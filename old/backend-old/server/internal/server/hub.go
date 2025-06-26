package server

import (
	"log"
	"net/http"
	"server/internal/server/entities"
	"server/internal/server/objects"
	"server/pkg/packets"
)

type ClientStateHandler interface {
	Name() string
	SetClient(client ClientInterfacer)
	OnEnter()
	HandleMessage(senderId uint64, message packets.Msg)
	OnExit()
}

type ClientInterfacer interface {
	Id() uint64
	ProcessMessage(senderId uint64, message packets.Msg)
	Initialize(id uint64)
	SocketSend(message packets.Msg)
	SocketSendAs(message packets.Msg, senderId uint64)
	PassToPeer(message packets.Msg, peerId uint64)
	Broadcast(message packets.Msg)
	ReadPump()
	WritePump()
	Close(reason string)
	SetState(state ClientStateHandler)
}

type Hub struct {
	Clients        *objects.SharedCollection[ClientInterfacer]
	BroadcastChan  chan *packets.Packet
	RegisterChan   chan ClientInterfacer
	UnregisterChan chan ClientInterfacer
	EntityManager  *entities.EntityManager
}

func NewHub() *Hub {
	return &Hub{
		Clients:        objects.NewSharedCollection[ClientInterfacer](),
		BroadcastChan:  make(chan *packets.Packet),
		RegisterChan:   make(chan ClientInterfacer),
		UnregisterChan: make(chan ClientInterfacer),
		EntityManager:  entities.NewEntityManager(0), // Server has authority ID 0
	}
}

func (h *Hub) Run() {
	log.Println("[I] Server started")
	log.Println("[I] Awaiting client connections")
	for {
		select {
		case client := <-h.RegisterChan:
			clientID := h.Clients.Add(client)
			client.Initialize(clientID)
			h.sendExistingEntities(client)

		case client := <-h.UnregisterChan:
			h.Clients.Remove(client.Id())

		case packet := <-h.BroadcastChan:
			h.handlePacket(packet)
		}
	}
}

func (h *Hub) handlePacket(packet *packets.Packet) {
	switch msg := packet.Msg.(type) {
	case *packets.Packet_SpawnEntity:
		h.handleSpawnEntity(packet.SenderId, msg.SpawnEntity)
	case *packets.Packet_EntityUpdate:
		h.handleEntityUpdate(packet.SenderId, msg.EntityUpdate)
	case *packets.Packet_EntityDespawn:
		h.handleEntityDespawn(packet.SenderId, msg.EntityDespawn)
	default:
		// Handle other message types or broadcast normally
		h.broadcastToOthers(packet)
	}
}

func (h *Hub) handleSpawnEntity(senderID uint64, spawnMsg *packets.SpawnEntityMessage) {
	log.Printf("[I] Spawning entity: %s at (%.2f, %.2f, %.2f) in instance: %d", 
		spawnMsg.DisplayName, spawnMsg.XPos, spawnMsg.YPos, spawnMsg.ZPos, spawnMsg.InstanceId)

	// Spawn the entity
	entity := h.EntityManager.SpawnEntity(spawnMsg)

	// Create spawn notification
	spawnedMsg := &packets.EntitySpawnedMessage{
		Entity: entity.ToProtobuf(),
	}

	// Broadcast to all clients in the same instance
	spawnPacket := &packets.Packet{
		SenderId: 0, // Server authority
		Msg: &packets.Packet_EntitySpawned{
			EntitySpawned: spawnedMsg,
		},
	}

	h.broadcastToInstance(spawnPacket, spawnMsg.InstanceId)
}

func (h *Hub) handleEntityUpdate(senderID uint64, updateMsg *packets.EntityUpdateMessage) {
	log.Printf("[I] Updating entity: %d in instance: %d", updateMsg.EntityId, updateMsg.InstanceId)

	if h.EntityManager.UpdateEntity(updateMsg.EntityId, updateMsg.InstanceId, updateMsg.Entity) {
		// Broadcast update to all other clients in the same instance
		updatePacket := &packets.Packet{
			SenderId: senderID,
			Msg: &packets.Packet_EntityUpdate{
				EntityUpdate: updateMsg,
			},
		}
		h.broadcastToInstanceExcept(updatePacket, updateMsg.InstanceId, senderID)
	} else {
		log.Printf("[W] Failed to update entity: %d in instance: %d (not found)", updateMsg.EntityId, updateMsg.InstanceId)
	}
}

func (h *Hub) handleEntityDespawn(senderID uint64, despawnMsg *packets.EntityDespawnMessage) {
	log.Printf("[I] Despawning entity: %d from instance: %d", despawnMsg.EntityId, despawnMsg.InstanceId)

	if h.EntityManager.DespawnEntity(despawnMsg.EntityId, despawnMsg.InstanceId) {
		// Broadcast despawn to all clients in the same instance
		despawnPacket := &packets.Packet{
			SenderId: 0, // Server authority
			Msg: &packets.Packet_EntityDespawn{
				EntityDespawn: despawnMsg,
			},
		}
		h.broadcastToInstance(despawnPacket, despawnMsg.InstanceId)
	} else {
		log.Printf("[W] Failed to despawn entity: %d from instance: %d (not found)", despawnMsg.EntityId, despawnMsg.InstanceId)
	}
}

func (h *Hub) sendExistingEntities(client ClientInterfacer) {
	// TODO: Send entities based on client's current instances
	// For now, send all entities from all instances
	entities := h.EntityManager.GetAllEntities()
	log.Printf("[I] Sending %d existing entities to client %d", len(entities), client.Id())

	for _, entity := range entities {
		spawnedMsg := &packets.EntitySpawnedMessage{
			Entity: entity.ToProtobuf(),
		}

		packet := &packets.Packet{
			SenderId: 0, // Server authority
			Msg: &packets.Packet_EntitySpawned{
				EntitySpawned: spawnedMsg,
			},
		}

		client.ProcessMessage(0, packet.Msg)
	}
}

// Send entities from specific instances to a client
func (h *Hub) sendEntitiesFromInstances(client ClientInterfacer, instanceIDs []uint64) {
	var entityCount int
	
	for _, instanceID := range instanceIDs {
		entities := h.EntityManager.GetEntitiesInInstance(instanceID)
		entityCount += len(entities)
		
		for _, entity := range entities {
			spawnedMsg := &packets.EntitySpawnedMessage{
				Entity: entity.ToProtobuf(),
			}

			packet := &packets.Packet{
				SenderId: 0, // Server authority
				Msg: &packets.Packet_EntitySpawned{
					EntitySpawned: spawnedMsg,
				},
			}

			client.ProcessMessage(0, packet.Msg)
		}
	}
	
	log.Printf("[I] Sent %d entities from %d instances to client %d", entityCount, len(instanceIDs), client.Id())
}

func (h *Hub) broadcastToAll(packet *packets.Packet) {
	h.Clients.ForEach(func(clientID uint64, client ClientInterfacer) {
		client.ProcessMessage(packet.SenderId, packet.Msg)
	})
}

func (h *Hub) broadcastToOthers(packet *packets.Packet) {
	h.Clients.ForEach(func(clientID uint64, client ClientInterfacer) {
		if clientID != packet.SenderId {
			client.ProcessMessage(packet.SenderId, packet.Msg)
		}
	})
}

func (h *Hub) broadcastToInstance(packet *packets.Packet, instanceID uint64) {
	// TODO: Track which clients are in which instances
	// For now, broadcast to all clients
	h.broadcastToAll(packet)
}

func (h *Hub) broadcastToInstanceExcept(packet *packets.Packet, instanceID uint64, excludeClientID uint64) {
	// TODO: Track which clients are in which instances
	// For now, broadcast to all other clients
	h.broadcastToOthers(packet)
}

func (h *Hub) Serve(getNewClient func(*Hub, http.ResponseWriter, *http.Request) (ClientInterfacer, error), writer http.ResponseWriter, request *http.Request) {
	log.Println("[I] New client connected from", request.RemoteAddr)
	client, err := getNewClient(h, writer, request)

	if err != nil {
		log.Printf("[E] Failed to obtain client for new connection: %v", err)
		return
	}

	h.RegisterChan <- client

	go client.WritePump()
	go client.ReadPump()
}
