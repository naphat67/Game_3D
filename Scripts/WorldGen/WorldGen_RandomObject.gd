class_name WorldGen_RandomObject extends Node

@export var ObjectsToActivate: Array[Node] = []
@export var ObjectsToDeactivate: Array[Node] = []
@export var DeleteDeactivated: bool = true
@export var SameAs: WorldGen_RandomObject = null
@export var Invert: bool = false
@export var Probability: float = 0
var Activated: bool = false
var RNG: RandomNumberGenerator = RandomNumberGenerator.new()
static var asldk = false

func SetSeed(Seed: int) -> void:
	RNG.seed = Seed

func Init() -> void:
	Activated = RNG.randf_range(0, 1) < Probability if (SameAs == null) else SameAs.Activated
	Activated = !Activated if (Invert) else Activated
	
	var deactivatedObjs = []
	
	for obj in ObjectsToActivate:
		if (Activated):
			obj.process_mode = Node.PROCESS_MODE_INHERIT
			obj.show()
			
			if (obj in deactivatedObjs):
				deactivatedObjs.erase(obj)
		else:
			obj.process_mode = Node.PROCESS_MODE_DISABLED
			obj.hide()
			
			if (obj not in deactivatedObjs):
				deactivatedObjs.append(obj)
	
	for obj in ObjectsToDeactivate:
		if (Activated):
			obj.process_mode = Node.PROCESS_MODE_DISABLED
			obj.hide()
			
			if (obj not in deactivatedObjs):
				deactivatedObjs.append(obj)
		else:
			obj.process_mode = Node.PROCESS_MODE_INHERIT
			obj.show()
			
			if (obj in deactivatedObjs):
				deactivatedObjs.erase(obj)
	
	for obj in deactivatedObjs:
		obj.queue_free()
