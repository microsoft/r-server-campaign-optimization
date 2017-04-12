While you can follow along on the VM, you may also execute the code on your own computer if you wish. But first you must perform the following steps. 

### On the VM: Configure VM for remote access

To do so, you will first need to open the Windows firewall on the VM to allow a connection to the SQL Server. To configure the firewall, execute the following command in a PowerShell window on the VM:

    netsh advfirewall firewall add rule name="SQLServer" dir=in action=allow protocol=tcp localport=1433 

SQL Server on the VM has been set up with a user `rdemo` and a default password of `D@tascience`.  Once you open the firewall, you may also want to also change the password, as anyone who knows the IP address can now access the server.  To do so, log into SSMS with Windows Authentication and execute the following query:
    
        ALTER LOGIN rdemo WITH PASSWORD = 'newpassword';  
       
## On your local computer:  Install R Client and obtain code

If you use your own computer you will also need to have a copy of [R Client](https://msdn.microsoft.com/en-us/microsoft-r/install-r-client-windows) on your local machine, installed and configured for your IDE. 

Also you will need a copy of the solution code.  Open a PowerShell window, navigate to the directory of your choice, and execute the following command:  

    git clone https://github.com/Microsoft/r-server-campaign-optimization.git

This will create a folder **r-server-campaign-optimization** containing the full solution package.

Finally, in the **sql_connection.R file, replace  `localhost` in the connection_string with the DNS of the VM followed by ",1433".

