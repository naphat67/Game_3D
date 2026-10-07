from typing import Any
from websockets.asyncio.server import ServerConnection as WSConnection
import os
import json
import argparse
import asyncio
import websockets
import hashlib
import traceback
import classes
import config

async def SendData(Socket: WSConnection, Data: str) -> None:
    data = Data
    chunks = []

    while (len(data) > 8192):
        chunks.append(data[:8192])
        data = data[8192:]

    chunks.append(data)
    
    for d in chunks:
        await Socket.send(d)

    await Socket.send("--END--")

async def RecvData(Socket: WSConnection) -> str:
    recvData = ""

    while (True):
        recv = await Socket.recv(decode = True)
        recv = recv.strip()

        if (len(recv) == 0):
            return ""

        recvData += recv[:recv.rfind("--END--")] if (recv.endswith("--END--")) else recv

        if (recv.endswith("--END--")):
            break

    return recvData.strip()

async def ClientReceive(Socket: WSConnection, Data: str, Player: classes.Player) -> None:
    global LoggedPlayers

    if (len(Data) == 0):
        raise ValueError("No data. Probably connection closed.")

    try:
        parsedData: dict[str, Any] = json.loads(Data)
        action: str = parsedData["action"] if ("action" in parsedData) else ""
        arguments: list[Any] = parsedData["arguments"] if ("arguments" in parsedData) else []
        result_code: str = "OK"
        result_args: list[Any] = []

        if (action == "is_authorized"):
            result_args.append(Player in LoggedPlayers)
        elif (action == "connect" and Player not in LoggedPlayers):
            await asyncio.sleep(0.1)

            username = arguments[0]
            passwdHash = hashlib.sha3_512(arguments[1].encode("utf-8")).hexdigest()
            playerFound = False

            for player in INFO.Players:
                if (player.Username == username):
                    playerFound = True

                    if (player.AuthHash == passwdHash):
                        for k, v in player.GetDictionary_Save().items():
                            setattr(Player, k, v)

                        LoggedPlayers.append(Player)

                    break

            if (Player not in LoggedPlayers and playerFound):
                result_code = "FAILED"
                result_args.append("Incorrect credentials.")
            elif (Player not in LoggedPlayers and not playerFound):
                Player.Username = username
                Player.AuthHash = passwdHash

                if (Player not in INFO.Players):
                    INFO.Players.append(Player)

                LoggedPlayers.append(Player)
        elif (Player not in LoggedPlayers):
            result_code = "FAILED"
            result_args.append("Player is not logged in.")  # Make sure the player exists
        elif (action == "set_pos"):
            x, y, z = arguments[0], arguments[1], arguments[2]
            Player.Position = (x, y, z)
        elif (action == "set_rot"):
            x, y, z = arguments[0], arguments[1], arguments[2]
            Player.Rotation = (x, y, z)
        elif (action == "set_scl"):
            x, y, z = arguments[0], arguments[1], arguments[2]
            Player.Scale = (x, y, z)
        elif (action == "set_running"):
            Player.Running = arguments[0]
        elif (action == "set_crouched"):
            Player.Crouched = arguments[0]
        elif (action == "set_lvl"):
            Player.CurrentLevel = arguments[0]
        elif (action == "set_sounds"):
            Player.Sounds = arguments[0]
        elif (action == "get_lvls_data"):
            result_args.append([lvl.GetDictionary_Player() for lvl in INFO.Worlds])
        elif (action == "get_all_players"):
            result_args.append([p.GetDictionary_Player(p == Player) for p in LoggedPlayers])
        else:
            result_code = "NOT FOUND"

        await SendData(Socket, json.dumps({"code": result_code, "args": result_args}))
    except Exception as ex:
        await SendData(Socket, json.dumps({"code": "FAILED", "args": "Unknown error."}))

async def ClientConnected(Socket: WSConnection) -> None:
    global Clients, LoggedPlayers

    if (len(Clients) >= CONFIG.Server["MaxPlayers"]):
        await SendData(Socket, "MAX_CONNECTIONS")
        await Socket.close()

        return

    Clients.append(Socket)
    player = classes.Player(len(Clients))

    try:
        while (True):
            try:
                data = await RecvData(Socket)
                await ClientReceive(Socket, data, player)
            except:
                break
    finally:
        if (player in LoggedPlayers):
            LoggedPlayers.remove(player)

        Clients.remove(Socket)
        await Socket.close()

def ReadConfig() -> config.Config:
    if (os.path.exists(args.CONFIG_FILE)):
        with open(args.CONFIG_FILE, "r") as f:
            conf = json.loads(f.read())
        
        return config.Config.FromDict(conf)
    
    conf = config.Config()

    with open(args.CONFIG_FILE, "x") as f:
        f.write(json.dumps(conf.ToDict(), indent = 4))
    
    return conf

def ReadInfo() -> config.Info:
    if (os.path.exists(args.INFO_FILE)):
        with open(args.INFO_FILE, "r") as f:
            info = json.loads(f.read())
        
        return config.Info.FromDict(info)
    
    info = config.Info()

    with open(args.INFO_FILE, "x") as f:
        f.write(json.dumps(info.ToDict(), indent = 4))
    
    return info

async def __start_server__() -> None:
    global Server, ServerStarted

    Server = await websockets.serve(
        handler = ClientConnected,
        host = CONFIG.Server["Host"],
        port = CONFIG.Server["Port"],
        max_size = 8192,
        ssl = None  # TODO: Add SSL
    )
    ServerStarted = True
    print(f"Server started at '{CONFIG.Server['Host']}:{CONFIG.Server['Port']}'.", flush = True)

    if (True):  # TODO: Change to SSL
        print(f"WARNING! SSL is not configured. This will NOT encrypt the connection! Please, use a valid SSL certificate.")

    while (ServerStarted):
        await asyncio.sleep(0.1)

    await __stop_server__()

async def __stop_server__() -> None:
    global Server, Clients

    for client in Clients:
        await client.Close()

    Server.close(True)
    await Server.wait_closed()

parser = argparse.ArgumentParser(prog = "BWI Server", description = "Start a BWI server.")
parser.add_argument("--config", dest = "CONFIG_FILE", type = str, default = "./config.json", required = False, help = "Configuration file.")
parser.add_argument("--info", dest = "INFO_FILE", type = str, default = "./info.json", required = False, help = "Information file.")

args = parser.parse_args()

CONFIG = ReadConfig()
INFO = ReadInfo()

LoggedPlayers: list[classes.Player] = []
Clients: list[WSConnection] = []

if (__name__ == "__main__"):
    asyncio.set_event_loop(asyncio.new_event_loop())

    try:
        asyncio.get_event_loop().run_until_complete(__start_server__())
    except KeyboardInterrupt:
        pass
    finally:
        print("\nClosing server...", flush = True)
        ServerStarted = False

        print("Server closed.", flush = True)
