# AgnesOS
Computercraft OS for my gf


## Installation

### Install on the computer
Use the main AgnesOS installer on the computer that will control the turtles:

`wget run https://raw.githubusercontent.com/halocore099/AgnesOS/main/install.lua`

### Install on each turtle
Use the turtle installer on each turtle that should connect to AgnesOS:

`wget run https://raw.githubusercontent.com/halocore099/AgnesOS/main/turtle_install.lua`

Then run the turtle agent on the turtle:

`system/turtle_agent.lua`

### How it works
The computer runs the AgnesOS dashboard and discovers turtles over rednet. Turtles receive strip mining jobs from the controller and report status back to the computer.
