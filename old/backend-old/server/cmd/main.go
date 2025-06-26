package main

import (
    "flag"
    "fmt"
    "log"
    "net/http"
    "server/internal/server"
    "server/internal/clients"
)

var (
    port = flag.Int("port", 8080, "Port to listen on.")
)

func main() {
    flag.Parse()

    hub := server.NewHub()

    http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
        hub.Serve(clients.NewWebSocketClient, w, r)
    })

    go hub.Run()
    addr := fmt.Sprintf(":%d", *port)
    err := http.ListenAndServe(addr, nil)

    if err != nil {
        log.Fatalf("Failed to start sever: %v", err)
    }
}

/*
func main_old() {
    client_id := packets.NewId(42)

    fmt.Println("Client:", client_id)

    packet := &packets.Packet{
        SenderId: 42,
        Msg: packets.NewCredential("admin", "nimda"),
        }

    fmt.Println("Packet:", packet)

    data, err := proto.Marshal(packet)

    if err != nil {
        panic(err)
    }

    fmt.Println("Bytes:", data)
}
*/
