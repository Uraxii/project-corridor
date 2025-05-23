package server

import (
	"log"
	"net/http"
	"server/pkg/packets"
)

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
	Clients map[uint64]ClientInterfacer

	BroadcastChan chan *packets.Packet

	RegisterChan chan ClientInterfacer

	UnregisterChan chan ClientInterfacer
}

func NewHub() *Hub {
	return &Hub{
		Clients:		make(map[uint64]ClientInterfacer),
		BroadcastChan:	make(chan *packets.Packet),
		RegisterChan:	make(chan ClientInterfacer),
		UnregisterChan:	make(chan ClientInterfacer),
	}
}

func (h *Hub) Run() {
	log.Println("Awaiting client registrations")
	for {
		select {
		case client := <- h.RegisterChan:
			client.Initialize(uint64(len(h.Clients)))
		case client := <- h.UnregisterChan:
			h.Clients[client.Id()] = nil
		case packet := <- h.BroadcastChan:
			for id, client := range h.Clients {
				if id != packet.SenderId {
					client.ProcessMessage(packet.SenderId, packet.Msg)
				}
			}
		}
	}
}

func (h *Hub) Serve(getNewClient func(*Hub, http.ResponseWriter, *http.Request) (ClientInterfacer, error), writer http.ResponseWriter, request *http.Request) {
	log.Println("New client connected from", request.RemoteAddr)
	client, err := getNewClient(h, writer, request)

	if err != nil {
		log.Printf("Error obtaining client for new connection: %v", err)
		return
	}

	h.RegisterChan <- client

	go client.WritePump()
	go client.ReadPump()
}
