package objects

import("sync")

type SharedCollection[T any] struct{
	objectsMap	map[uint64]T
	nextId		uint64
	mapMux		sync.Mutex
}

func NewSharedCollection[T any](capacity ...int) *SharedCollection[T] {
	var newObjMap map[uint64]T

	if len(capacity) > 0 {
		newObjMap = make(map[uint64]T, capacity[0])
	} else {
		newObjMap = make(map[uint64]T)
	}

	return &SharedCollection[T]{
		objectsMap: newObjMap,
		nextId:		1,
	}
}

func(s *SharedCollection[T]) Add(obj T, id ...uint64) uint64 {
	s.mapMux.Lock()
	defer s.mapMux.Unlock()

	thisId := s.nextId
	if len(id) > 0 {
		thisId = id[0]
	}

	s.objectsMap[thisId] = obj
	s.nextId++
	return thisId
}

func (s *SharedCollection[T]) Remove(id uint64) {
	s.mapMux.Lock()
	defer s.mapMux.Unlock()

	delete(s.objectsMap, id)
}

func (s *SharedCollection[T]) ForEach(callback func(uint64, T)) {
	s.mapMux.Lock()
	mapCopy := make(map[uint64]T, len(s.objectsMap))

	for id, obj := range s.objectsMap {
		mapCopy[id] = obj
	}

	s.mapMux.Unlock()

	for id, obj := range mapCopy {
		callback(id, obj)
	}
}

func (s *SharedCollection[T]) Get(id uint64) (T, bool) {
	s.mapMux.Lock()
	defer s.mapMux.Unlock()

	obj, found := s.objectsMap[id]
	return obj, found
}

func (s *SharedCollection[T]) Len() int {
	s.mapMux.Lock()
	defer s.mapMux.Unlock()

	return len(s.objectsMap)
}
