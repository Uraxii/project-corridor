package server

import (
	"log"
	"net/http"
	"server/pkg/packets"
	"server/internal/server/objects"
)

type ClientStateHandler interface {
	Name() string

	// Set Client to own the state.
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
}

type Hub struct {
	Clients *objects.SharedCollection[ClientInterfacer]
	BroadcastChan chan *packets.Packet
	RegisterChan chan ClientInterfacer
	UnregisterChan chan ClientInterfacer
}

func NewHub() *Hub {
	return &Hub{
		Clients:		objects.NewSharedCollection[ClientInterfacer](),
		BroadcastChan:	make(chan *packets.Packet),
		RegisterChan:	make(chan ClientInterfacer),
		UnregisterChan:	make(chan ClientInterfacer),
	}
}

func (h *Hub) Run() {
	log.Println("[I] Server started")
	log.Println("[I] Awaiting client connections")
	for {
		select {
		case client := <- h.RegisterChan:
			client.Initialize(h.Clients.Add(client))
		case client := <- h.UnregisterChan:
			h.Clients.Remove(client.Id())
		case packet := <- h.BroadcastChan:
			h.Clients.ForEach(func(clientId uint64, client ClientInterfacer){
				if clientId != packet.SenderId {
					client.ProcessMessage(packet.SenderId, packet.Msg)
				}
			})
		}
	}
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
