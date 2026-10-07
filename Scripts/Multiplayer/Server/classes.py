from enum import Enum
from typing import Any, Self
import random
import copy
import globals

def GetRandomID() -> int:
    return random.randint(0, 2 ** 31 - 1)

class EntityRole(Enum):
    NEUTRAL = 0
    PASSIVE = 1
    AGGRESSIVE = 2

class EntityType(Enum):
    HOWLER = 0
    SMILER = 1
    WINDOWS = 2
    CLUMP_MALE = 3
    CLUMP_FEMALE = 4
    CLUMP_BABY = 5
    SKINSTEALER = 6
    I40 = 7

class EntityState(Enum):
    WANDERING = 0
    TRIGGERED = 1

class Permission(Enum):
    NONE = 0
    INTERACT = 1
    MOVE = 2
    INTERACT_MOVE = 3

class ChatMessage(globals.BaseGameElement):
    def __init__(self, Username: str, Content: list[dict[str, str]] | str) -> None:
        self.Username = Username

        if (isinstance(Content, list)):
            self.Content = Content
        else:
            self.Content = [{"type": "text", "text": str(self.Content)}]

class MapChunk(globals.BaseGameElement):
    def __init__(self, Position: tuple[int, int, int]) -> None:
        super().__init__()

        self.Position: tuple[int, int, int] = Position
        self.DisabledIDs: list[str] = []  # Disabled items, entities, etc.

class Map(globals.BaseGameElement):
    def __init__(self, Name: str, Seed: int = -1) -> None:
        super().__init__()

        self.Name = Name
        self.NoiseMaps: list[str] | None = None  # null = use the ones set in the game
        self.Seed: int = Seed if (Seed >= 0) else GetRandomID()
        self.ChunkData: list[MapChunk] = []

class GameEntity(globals.BaseGameElement):
    def __init__(self, ID: int, IDPreffix: str = "GENT") -> None:
        super().__init__()

        self.IDPreffix: str = IDPreffix
        self.ID: int = ID
        self.Position: tuple[float, float, float] = (0, 0, 0)
        self.Rotation: tuple[float, float, float] = (0, 0, 0)
        self.Scale: tuple[float, float, float] = (1, 1, 1)
        self.Health: float = 100

    def GetID(self) -> str:
        return f"{self.IDPreffix}_{self.ID}"
    
    def GetDictionary_Save(self) -> dict[str, Any]:
        return super().GetDictionary_Save()

    def GetDictionary_Player(self) -> dict[str, Any]:
        return super().GetDictionary_Player()

class Item(GameEntity):
    def __init__(self, ID: int, Name: str) -> None:
        super().__init__(ID, "ITEM")

        self.Name: str = Name
        self.Tags: list[str] = []
        self.Seed: int = GetRandomID()
        self.OwnerID: str | None = None
        self.Permissions_Groups: Permission = Permission.INTERACT_MOVE
        self.Permissions_Everyone: Permission = Permission.NONE

class Player(GameEntity):
    def __init__(self, ID: int) -> None:
        super().__init__(ID, "PLAYER")

        # Identity
        self.Username: str = ""
        self.AuthHash: str | None = None

        # Data
        self.Running: bool = False
        self.Crouched: bool = False
        self.CurrentLevel: str = ""
        self.Tags: list[str] = []

        # Survival
        self.Water: float = 100
        self.Food: float = 100
        self.Stamina: float = 100

        # Groups
        self.Groups: list[str] = []

        # Items
        self.Items: list[str] = []
        self.ItemInHand: int | None = None  # Index of self.Items

        # Sounds
        self.Sounds: list[int] = []

    def GetDictionary_Player(self, IsSelf: bool) -> dict[str, Any]:
        d = super().GetDictionary_Player()
        d.pop("AuthHash")
        d.pop("ID")
        d.pop("IDPreffix")
        
        if (IsSelf):
            d.pop("Water")
            d.pop("Food")
            d.pop("Health")
            d.pop("Stamina")
            d.pop("Items")
            d.pop("Sounds")
        
        return d
    
    def GetDictionary_Save(self):
        d = super().GetDictionary_Save()
        #d.pop("Sounds")

        return d

class Entity(GameEntity):
    def __init__(self, ID: int, Type: EntityType, Role: EntityRole) -> None:
        super().__init__(ID, "ENTITY")

        self.EntRole: EntityRole = Role
        self.EntType: EntityType = Type
        self.State: EntityState = EntityState.WANDERING
        self.TargetID: str | None = None
