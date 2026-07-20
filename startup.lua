-- AgnesOS Bootloader
-- Version 1.0.0

term.clear()
term.setCursorPos(1,1)

print("========================")
print("       AgnesOS")
print("       Bootloader")
print("========================")
print("")

if fs.exists("system/updater.lua") then
    shell.run("system/updater")
else
    print("Updater missing")
end

sleep(1)

shell.run("AgnesOS")
