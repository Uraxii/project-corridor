package entities

import (
	"server/pkg/packets"
	"sync"
	"sync/atomic"
)

// Stat represents a game stat with current, max, and extra values
type Stat struct {
	Current float32
	Max     float32
	Extra   float32
}

// Entity represents a game entity with all its data
type Entity struct {
	AuthorityID      uint64
	EntityID         uint64   // Unique entity identifier
	InstanceID       uint64   // Which instance/zone this entity is in
	DisplayName      string
	Model            string
	State            string
	XPos             float32
	YPos             float32
	ZPos             float32
	EquippedItemIDs  []uint64
	Stats            map[string]*Stat
	mutex            sync.RWMutex
}

// NewEntity creates a new entity with the given parameters
func NewEntity(authorityID, entityID, instanceID uint64, displayName, model, state string, x, y, z float32) *Entity {
	return &Entity{
		AuthorityID:     authorityID,
		EntityID:        entityID,
		InstanceID:      instanceID,
		DisplayName:     displayName,
		Model:           model,
		State:           state,
		XPos:            x,
		YPos:            y,
		ZPos:            z,
		EquippedItemIDs: make([]uint64, 0),
		Stats:           make(map[string]*Stat),
	}
}

// SetStat sets a stat value for the entity
func (e *Entity) SetStat(name string, current, max, extra float32) {
	e.mutex.Lock()
	defer e.mutex.Unlock()
	e.Stats[name] = &Stat{
		Current: current,
		Max:     max,
		Extra:   extra,
	}
}

// GetStat gets a stat value for the entity
func (e *Entity) GetStat(name string) (*Stat, bool) {
	e.mutex.RLock()
	defer e.mutex.RUnlock()
	stat, exists := e.Stats[name]
	return stat, exists
}

// UpdatePosition updates the entity's position
func (e *Entity) UpdatePosition(x, y, z float32) {
	e.mutex.Lock()
	defer e.mutex.Unlock()
	e.XPos = x
	e.YPos = y
	e.ZPos = z
}

// ToProtobuf converts the entity to a protobuf message
func (e *Entity) ToProtobuf() *packets.EntityDataMessage {
	e.mutex.RLock()
	defer e.mutex.RUnlock()

	// Convert stats to protobuf map
	statsMap := make(map[string]*packets.StatMessage)
	for name, stat := range e.Stats {
		statsMap[name] = &packets.StatMessage{
			Current: stat.Current,
			Max:     stat.Max,
			Extra:   stat.Extra,
		}
	}

	// Copy equipped items
	equippedItems := make([]uint64, len(e.EquippedItemIDs))
	copy(equippedItems, e.EquippedItemIDs)

	return &packets.EntityDataMessage{
		AuthorityId:      e.AuthorityID,
		EntityId:         e.EntityID,
		InstanceId:       e.InstanceID,
		DisplayName:      e.DisplayName,
		Model:            e.Model,
		State:            e.State,
		XPos:             e.XPos,
		YPos:             e.YPos,
		ZPos:             e.ZPos,
		EquippedItemIds:  equippedItems,
		Stats:            statsMap,
	}
}

// EntityManager manages all entities on the server
type EntityManager struct {
	entities           map[uint64]map[uint64]*Entity // instanceID -> entityID -> Entity
	nextEntityID       uint64
	serverAuthorityID  uint64
	mutex              sync.RWMutex
}

// NewEntityManager creates a new entity manager
func NewEntityManager(serverAuthorityID uint64) *EntityManager {
	return &EntityManager{
		entities:          make(map[uint64]map[uint64]*Entity),
		nextEntityID:      1,
		serverAuthorityID: serverAuthorityID,
	}
}

// SpawnEntity spawns a new entity and returns it
func (em *EntityManager) SpawnEntity(spawnMsg *packets.SpawnEntityMessage) *Entity {
	em.mutex.Lock()
	defer em.mutex.Unlock()

	// Assign new entity ID
	entityID := atomic.AddUint64(&em.nextEntityID, 1)
	instanceID := spawnMsg.InstanceId

	// Create entity
	entity := NewEntity(
		em.serverAuthorityID,
		entityID,
		instanceID,
		spawnMsg.DisplayName,
		spawnMsg.Model,
		spawnMsg.State,
		spawnMsg.XPos,
		spawnMsg.YPos,
		spawnMsg.ZPos,
	)

	// Set equipped items
	if spawnMsg.EquippedItemIds != nil {
		entity.EquippedItemIDs = make([]uint64, len(spawnMsg.EquippedItemIds))
		copy(entity.EquippedItemIDs, spawnMsg.EquippedItemIds)
	}

	// Set stats
	for name, statMsg := range spawnMsg.Stats {
		entity.SetStat(name, statMsg.Current, statMsg.Max, statMsg.Extra)
	}

	// Ensure instance exists
	if em.entities[instanceID] == nil {
		em.entities[instanceID] = make(map[uint64]*Entity)
	}

	// Store entity
	em.entities[instanceID][entityID] = entity

	return entity
}

// GetEntity retrieves an entity by entity ID and instance ID
func (em *EntityManager) GetEntity(entityID, instanceID uint64) (*Entity, bool) {
	em.mutex.RLock()
	defer em.mutex.RUnlock()
	
	instanceEntities, instanceExists := em.entities[instanceID]
	if !instanceExists {
		return nil, false
	}
	
	entity, entityExists := instanceEntities[entityID]
	return entity, entityExists
}

// GetEntitiesInInstance returns all entities in a specific instance
func (em *EntityManager) GetEntitiesInInstance(instanceID uint64) []*Entity {
	em.mutex.RLock()
	defer em.mutex.RUnlock()

	instanceEntities, exists := em.entities[instanceID]
	if !exists {
		return []*Entity{}
	}

	entities := make([]*Entity, 0, len(instanceEntities))
	for _, entity := range instanceEntities {
		entities = append(entities, entity)
	}
	return entities
}

// GetAllEntities returns all entities across all instances
func (em *EntityManager) GetAllEntities() []*Entity {
	em.mutex.RLock()
	defer em.mutex.RUnlock()

	var allEntities []*Entity
	for _, instanceEntities := range em.entities {
		for _, entity := range instanceEntities {
			allEntities = append(allEntities, entity)
		}
	}
	return allEntities
}

// GetAllInstances returns a list of all instance IDs that have entities
func (em *EntityManager) GetAllInstances() []uint64 {
	em.mutex.RLock()
	defer em.mutex.RUnlock()

	instances := make([]uint64, 0, len(em.entities))
	for instanceID := range em.entities {
		instances = append(instances, instanceID)
	}
	return instances
}

// DespawnEntity removes an entity from the manager
func (em *EntityManager) DespawnEntity(entityID, instanceID uint64) bool {
	em.mutex.Lock()
	defer em.mutex.Unlock()

	instanceEntities, instanceExists := em.entities[instanceID]
	if !instanceExists {
		return false
	}

	if _, entityExists := instanceEntities[entityID]; entityExists {
		delete(instanceEntities, entityID)
		
		// Clean up empty instance
		if len(instanceEntities) == 0 {
			delete(em.entities, instanceID)
		}
		
		return true
	}
	return false
}

// UpdateEntity updates an existing entity
func (em *EntityManager) UpdateEntity(entityID, instanceID uint64, updateData *packets.EntityDataMessage) bool {
	em.mutex.Lock()
	defer em.mutex.Unlock()

	instanceEntities, instanceExists := em.entities[instanceID]
	if !instanceExists {
		return false
	}

	entity, entityExists := instanceEntities[entityID]
	if !entityExists {
		return false
	}

	// Update entity data
	entity.mutex.Lock()
	defer entity.mutex.Unlock()

	if updateData.DisplayName != "" {
		entity.DisplayName = updateData.DisplayName
	}
	if updateData.Model != "" {
		entity.Model = updateData.Model
	}
	if updateData.State != "" {
		entity.State = updateData.State
	}

	entity.XPos = updateData.XPos
	entity.YPos = updateData.YPos
	entity.ZPos = updateData.ZPos

	if updateData.EquippedItemIds != nil {
		entity.EquippedItemIDs = make([]uint64, len(updateData.EquippedItemIds))
		copy(entity.EquippedItemIDs, updateData.EquippedItemIds)
	}

	// Update stats
	for name, statMsg := range updateData.Stats {
		entity.Stats[name] = &Stat{
			Current: statMsg.Current,
			Max:     statMsg.Max,
			Extra:   statMsg.Extra,
		}
	}

	return true
}
