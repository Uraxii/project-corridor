package clients

import (
	"fmt"
	"log"
	"net/http"

	"server/internal/server"
	"server/internal/server/states"
	"server/pkg/packets"

	"github.com/gorilla/websocket"
	"google.golang.org/protobuf/proto"
)

type WebSocketClient struct {
	id       uint64
	conn     *websocket.Conn
	hub      *server.Hub
	sendChan chan *packets.Packet
	state server.ClientStateHandler
	logger   *log.Logger
}

func NewWebSocketClient(hub *server.Hub, writer http.ResponseWriter, request *http.Request) (server.ClientInterfacer, error) {
	upgrader := websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
		CheckOrigin:     func(_ *http.Request) bool { return true },
	}

	conn, err := upgrader.Upgrade(writer, request, nil)
	if err != nil {
		return nil, err
	}

	c := &WebSocketClient{
		hub:      hub,
		conn:     conn,
		sendChan: make(chan *packets.Packet, 256),
		logger:   log.New(log.Writer(), "Client unknown: ", log.LstdFlags),
	}

	return c, nil
}

func (c *WebSocketClient) Id() uint64 {
	return c.id
}

func (c *WebSocketClient) SetState(state server.ClientStateHandler) {
	prevStateName := "None"
	if c.state != nil {
		prevStateName = c.state.Name()
		c.state.OnExit()
	}

	newStateName := "None"
	if state != nil {
		newStateName = state.Name()
	}

	c.logger.Printf("[D] Switching client %d from state %s to %s", c.id, prevStateName, newStateName)

	c.state = state

	if c.state != nil {
		c.state.SetClient(c)
		c.state.OnEnter()
	}
}

func (c *WebSocketClient) ProcessMessage(senderId uint64, message packets.Msg) {
	c.logger.Printf("[D] Received message: %T from client - echoing back", message)
	
	// MISSING: This line should be added around line 69
	if c.state != nil {
		c.state.HandleMessage(senderId, message)
	}

	if senderId == c.id {
		// This message was send by the local client. Forward to everyone.
		c.Broadcast(message)
		return
	}

	c.SocketSendAs(message, senderId)
}

func (c *WebSocketClient) Initialize(id uint64) {
	c.id = id
	c.logger.SetPrefix(fmt.Sprintf("Client %d: ", c.id))
	c.SetState(&states.Connected{})
}

func (c *WebSocketClient) SocketSend(message packets.Msg) {
	c.SocketSendAs(message, c.id)
}

func (c *WebSocketClient) SocketSendAs(message packets.Msg, senderId uint64) {
	select {
	case c.sendChan <- &packets.Packet{SenderId: senderId, Msg: message}:
	default:
		c.logger.Printf("[W] Send channel full, dropping message: %T", message)
	}
}

func (c *WebSocketClient) PassToPeer(message packets.Msg, peerId uint64) {
	if peer, exists := c.hub.Clients.Get(peerId); exists {
		peer.ProcessMessage(c.id, message)
	}
}

func (c *WebSocketClient) Broadcast(message packets.Msg) {
	c.hub.BroadcastChan <- &packets.Packet{SenderId: c.id, Msg: message}
}

func (c *WebSocketClient) ReadPump() {
    defer func() {
        c.logger.Println("[D] Closing read pump")
        c.Close("Read pump closed")
    }()

    for {
        messageType, data, err := c.conn.ReadMessage()
        if err != nil {
            if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
                c.logger.Printf("[E] %v", err)
            }
            break
        }

        // Handle JSON messages for testing
        if messageType == websocket.TextMessage {
			// TODO: Disable this in production.
            c.logger.Printf("[D] Received text message: %s", string(data))
            // For testing, just echo back or create a simple response
            testMsg := packets.NewId(c.id)
            c.SocketSend(testMsg)
        }

        // Handle binary protobuf messages
        packet := &packets.Packet{}
        if err := proto.Unmarshal(data, packet); err != nil {
            c.logger.Printf("[E] Failed to unmarshall data: %v", err)
            continue
        }

        if packet.SenderId == 0 {
            packet.SenderId = c.id
        }

        c.ProcessMessage(packet.SenderId, packet.Msg)
    }
}

func (c *WebSocketClient) WritePump() {
	defer func() {
		c.logger.Println("[D] Closing write pump")
		c.Close("Write pump closed")
	}()

	for packet := range c.sendChan {
		writer, err := c.conn.NextWriter(websocket.BinaryMessage)
		if err != nil {
			c.logger.Printf("[E] Faile to get writer for %T packet, closing client: %v", packet.Msg, err)
			continue
		}

		data, err := proto.Marshal(packet)
		if err != nil {
			c.logger.Printf("[E] Failed to marshall %T packet: %v", packet.Msg, err)
			continue
		}

		_, err = writer.Write(data)
		if err != nil {
			c.logger.Printf("[E] Failed to write %T packet: %v", packet.Msg, err)
			continue
		}

		if err := writer.Close(); err != nil {
			c.logger.Printf("[E] Faile to close writer for %T packet: %v", packet.Msg, err)
			continue
		}
	}
}

func (c *WebSocketClient) Close(reason string) {
	c.logger.Printf("[I] Closing client connection: %s", reason)

	c.hub.UnregisterChan <- c
	c.conn.Close()

	select {
	case <-c.sendChan:
	default:
		close(c.sendChan)
	}
}
