package packets

type Msg = isPacket_Msg

func NewCredentials(user string, secret string) Msg {
	return &Packet_Credential{
		Credential: &CredentialMessage{
			User: user,
			Secret: secret,
		},
	}
}

func NewId(id uint64) Msg {
	return &Packet_Id{
		Id: &IdMessage{
			Id: id,
		},
	}
}
