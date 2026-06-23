@abstract class_name NetworkOwnedObj extends Node

var owner_entity : Node

func setup(base_owner : Node):
	self.owner_entity = base_owner
