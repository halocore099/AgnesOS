-- AgnesOS Installer v1.0.0

local repo =
"https://raw.githubusercontent.com/YOURNAME/AgnesOS/main/"


print("========================")
print(" AgnesOS Installer")
print("========================")
print("")


local files = {

    "startup.lua",
    "AgnesOS.lua",
    "config.lua",
    "version.txt",
    "system/updater.lua"

}


if not fs.exists("system") then
    fs.makeDir("system")
end



for _,file in pairs(files) do

    print("Installing "..file)

    shell.run(
        "wget",
        repo..file,
        file
    )

end


print("")
print("Installation complete!")
print("")


sleep(2)

os.reboot()
