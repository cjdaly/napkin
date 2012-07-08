puts "hello"
puts self.class
helper
group = Sketchup.active_model.entities.add_group
text_group = group.entities.add_group
text_group.entities.add_3d_text "Hello World!", TextAlignLeft, "Courier New", false, false, 8, 1, 0, true, 0

face_group = group.entities.add_group
face = [text_group.bounds.corner(0), text_group.bounds.corner(1), text_group.bounds.corner(3), text_group.bounds.corner(2)]
face = face_group.entities.add_face face
face_group.entities.transform_entities [0,0,-1], face
face_group.material = "Blue"

group.entities.transform_entities [0,-10,0], group

