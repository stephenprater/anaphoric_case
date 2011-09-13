#Anaphoric Case

Provides an anaphoric if, and anaphoric case-like construct as kernel methods.

###Examples: 

English:  If the dog is on fire, put it out!

Ruby: If the dog is on fire, put the dog out!

This is all well and good provided dog is a simple reference, but if the dog
is something more complicated, you wind up either having to do an assign
in the if condition, or assign to a temporary variable before you extinguish
Fido.

This is similar to the use case for the andand gem.  It's especially handy
when the dog being on fire is not a simple binary condition.  If Rin-tin-tin
can summon help depending upon his dire situation, like if dog.fire also says
which *part* of the dog is on fire, or where he is drowning at.
  
    # Listen for sounds of distress
    if dog.fire
      owner.tell(dog.fire)
    elsif dog.drowning
      owner.tell(dog.drowning)
    elsif dog.hungry
      owner.tell(dog.hungry)
    end

An anaphoric if doesn't need to call `dog.fire` again in the executed block.

    aif(dog.fire) { |it| owner.tell(it) }

If you have multiple conditions, you probably want to use the switch/on construct
  
    owner.tell(switch do
      on dog.fire
      on dog.drowing
      on dog.hungry
    end)

Here, the dog will tell his owner the first condition he encounters.  `switch` can
also behave like a regular case statement (albiet with fallthrough) if you like.
   
    switch dog.name do
      on /Rover/ { |it| "Come on over #{it}"}
      on /Fido/  { |it| "Give #{it} a bone"}
      on /Rin-Tin-Tin/ { |it| "#{it} is frequently mistaken for Lassie"}
    end

If the switch parameter takes a block, it will be passed into the block as an optional
block parameter.  In addition, the `on` method will yield the parameter object of the 
`switch` method, rather than it's own parameter.

If `switch` is called with an explicit receiver, it acts somewhat like `tap` in that the
block is executed in the context of the receiver.
