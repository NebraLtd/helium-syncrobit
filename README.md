![Helium Syncrobit CM4 Firmware Repo Header](https://cdn.shopify.com/s/files/1/0071/2281/3001/files/Nebra-Firmware-Github-Header-Syncrobit_2x_226e8a2b-c506-4be7-a4d4-abfb892e1f6d.png?v=1672853314)

# helium-syncrobit
Balena OpenFleet for Syncrobit CM4 Miners

[![balena deploy button](https://www.balena.io/deploy.svg)](https://dashboard.balena-cloud.com/deploy?repoUrl=https://github.com/NebraLtd/helium-syncrobit)

# Takeover

Takeover is a tool to install Balena OpenFleet (with Nebra configuration) on a SyncroB.it unit currently running Chameleon OS.

1. SSH into the SyncroB.it unit.
2. Run the following command:

    curl -sSL https://github.com/NebraLtd/helium-syncrobit/blob/takeover-ccrisan/takeover.sh | bash

3. Wait for the command to complete (might take some time, depending on the Internet connection speed). The system will automatically reboot.
4. After rebooting, the Balena OS firmware image will actually be written to the SD card; the system will not be reachable at all during this period.
5. When the flashing is done, the system will reboot again, this time running the Balena OS.

**note**: Do not disconnect the SyncroB.it unit from power or Internet at all during the above procedure or you may brick it.
