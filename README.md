# Youtrack Extension for Telescope

Youtrack allows issue management via smart commits.
For the smart commits you need to know the issue ID.
This extension lists all Youtrack Issues assigned you,
shows a small description in the preview and returns the issue id on selection.
Also you might need to track your time spent on issues.
You'll be able to do it via the Youtrack Time Tracking plugin.

## How To

1. Install this repository with your favorite plugin manager.

   ```lua
   use 'ruslan-korneev/youtrack.nvim'
   ```

2. Add youtrack to the telescope extensions

   `url` and `token` are mandetory parameters.
   The query parameter can be optionally adjusted.

   <!--  TODO: implement the command for authentication  -->
   <!--   instead of writing the token in config -->

   ```lua
   extensions = {
       youtrack = {
           url = "https://youtrack.example.com",
           token = "perm:XXX",
           query = "for: me #Unresolved ",
       },
       ...
   }
   ```

3. Add keybindings. The extension can be started via:
   `Telescope youtrack`

   To leave telescope in insert mode:

   ```lua
       require("telescope").extensions.youtrack.youtrack({ insert_mode = true })
   ```
