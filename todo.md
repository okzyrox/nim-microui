- [ ] refactor GLFW overhead to a seperate module
- [ ] fix uint8Slider hack

- [ ] migrate C types to Nim Types
    - [ ] char ptr -> string
    - [ ] keyboard keys -> enum
    - [ ] mouse buttons -> enum
    - [ ] any `int`s used in place of enums that use weird left shift operations

- [ ] fix backspace/del on example

- [ ] add template that only needs to pass `MUContext` ref once
    
    i.e.:
    ```nim
    muUi(muCtx):
        muWindow("Window", rect(350, 250, 300, 240)):
            muHeader("Title"):
                muLabel("Hello!")
    ```

- [ ] documentation on custom controls