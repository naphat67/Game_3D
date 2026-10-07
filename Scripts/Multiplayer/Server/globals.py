from typing import Any, Self
import copy

class BaseData():
    __registry__ = {}

    def __init_subclass__(cls, **kwargs) -> None:
        super().__init_subclass__(**kwargs)
        cls.__registry__[cls.__name__] = cls
    
    def ToDict(self) -> dict[str, Any]:
        d = copy.deepcopy(self.__dict__)
        d["__type__"] = self.__class__.__name__

        for k, v in d.items():
            if (isinstance(v, list)):
                d[k] = [i.ToDict() if (hasattr(i, "ToDict")) else i.GetDictionary_Save() if (hasattr(i, "GetDictionary_Save")) else i for i in v]
            elif (hasattr(v, "ToDict")):
                d[k] = v.ToDict()
            elif (hasattr(v, "GetDictionary_Save")):
                d[k] = v.GetDictionary_Save()

        return d
    
    @classmethod
    def FromDict(cls, D: dict[str, Any]) -> Self:
        targetCls = cls.__registry__.get(D.get("__type__", cls.__name__), cls)
        instance = targetCls.__new__(targetCls)

        for k, v in D.items():
            if (k == "__type__"):
                continue

            if (isinstance(v, list)):
                v = [BaseData.FromDict(i) if (isinstance(i, dict) and "__type__" in i) else i for i in v]
            elif (isinstance(v, dict) and "__type__" in v):
                v = BaseData.FromDict(v)
            
            setattr(instance, k, v)
        
        return instance

class BaseGameElement(BaseData):
    def GetDictionary_Save(self) -> dict[str, Any]:
        return self.ToDict()
    
    def GetDictionary_Player(self) -> dict[str, Any]:
        return self.GetDictionary_Save()