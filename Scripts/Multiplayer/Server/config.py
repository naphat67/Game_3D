from typing import Any
import globals
import classes

class Config(globals.BaseData):
    def __init__(self) -> None:
        self.Server: dict[str, Any] = {"Host": "0.0.0.0", "Port": 65287, "MaxPlayers": 1000}
        self.PlayerAdminTag: str = "admin"

class Info(globals.BaseData):
    def __init__(self) -> None:
        self.Worlds: list[classes.Map] = [
            classes.Map("Level 0", -1)
        ]
        self.Players: list[classes.Player] = []
        self.Objects: list[classes.Item] = []
        self.ChatMessages: list[classes.ChatMessage] = []
