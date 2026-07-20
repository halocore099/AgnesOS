local config = require("config")


while true do

    term.clear()
    term.setCursorPos(1,1)


    print("========================")
    print("       "..config.NAME)
    print("       v"..config.VERSION)
    print("========================")
    print("")


    print("1. Mining")
    print("2. Utilities")
    print("3. Settings")
    print("4. Shutdown")
    print("")


    write("> ")

    local choice = read()



    if choice == "1" then

        term.clear()

        print("Mining system")
        print("Coming soon")

        sleep(2)



    elseif choice == "2" then

        term.clear()

        print("Utilities")
        print("Coming soon")

        sleep(2)



    elseif choice == "3" then

        term.clear()

        print("AgnesOS Settings")
        print("")
        print(
        "Version: "
        ..config.VERSION
        )

        sleep(3)



    elseif choice == "4" then

        term.clear()

        print("Shutting down...")
        sleep(1)

        os.shutdown()


    else

        print("Invalid option")
        sleep(1)

    end

end
